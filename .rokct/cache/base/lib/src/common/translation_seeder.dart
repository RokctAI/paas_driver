// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'dart:math' show min;

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/bundled_translations.dart';
import 'package:base_sdk/src/services/local_storage.dart';

/// Pushes the app's bundled translation KEYS to the backend so they exist
/// in the PaaS Translation doctype — strictly insert-only server-side:
/// keys the backend already has are never touched, so admin edits and the
/// backend-served values always win (the app keeps using them via the
/// existing splash fetch).
///
/// Candidate rows are:
///  * the active locale's bundled entries whose keys the just-fetched
///    served map does not contain (the served map is for the active
///    locale, so this is the only locale that can be diffed locally), and
///  * an `en` row for every key registered in any bundled locale,
///    humanized with [AppHelpers.humanizeTrKey] — the exact string the
///    UI's last-resort fallback would render. These are sent without
///    local diffing (except when `en` IS the active locale); the server's
///    insert-only skip makes over-sending harmless.
///
/// The push is fire-and-forget: it never blocks splash and never surfaces
/// anything to the user. A fingerprint of the candidate set (rows + app
/// version) is persisted only after a fully successful push, so a failed
/// attempt retries naturally on the next launch and an unchanged app
/// never re-pushes.
class TranslationSeeder {
  TranslationSeeder._();

  /// The manifest-registered whitelisted-method alias with the
  /// `{app_name}` segment dropped, resolved by the universal gateway.
  static const String cmd = 'api.translation.seed_missing_translations';

  /// The control-role gateway only resolves cmds carrying the verbatim
  /// `control:` prefix (see control hooks' override_whitelisted_methods),
  /// so this is the same endpoint's key on a control-role site. Apps can
  /// be pointed at any site role; [pushMissingKeys] falls back to this
  /// cmd when the unprefixed one fails.
  static const String controlCmd = 'control:seed_missing_translations';

  /// Keep comfortably under the server's per-call row cap (600).
  static const int maxRowsPerCall = 500;

  /// Mirrors the server-side value length cap; longer bundled values are
  /// left out client-side instead of burning a rejected row.
  static const int maxValueLength = 500;

  static bool _inFlight = false;

  /// Fire-and-forget entry point, called after a successful translation
  /// fetch (splash and language change). Errors are swallowed by design:
  /// the fingerprint is only stored on success, so the next launch simply
  /// tries again.
  static Future<void> pushMissingKeys() async {
    if (_inFlight) return;
    _inFlight = true;
    try {
      final rows = computeCandidateRows(
        servedMap: LocalStorage.getTranslations(),
        activeLocale: LocalStorage.getLanguage()?.locale,
      );
      if (rows.isEmpty) return;

      String appVersion = '';
      try {
        final info = await PackageInfo.fromPlatform();
        appVersion = '${info.version}+${info.buildNumber}';
      } catch (_) {
        // Fingerprint still works without the version salt.
      }

      final digest = fingerprint(rows, appVersion);
      if (LocalStorage.getSeededTranslationsHash() == digest) return;

      const gateway = PlatformGateway();
      try {
        await _pushChunks(gateway, cmd, rows);
      } catch (_) {
        // The unprefixed cmd resolves only on tenant-role sites; a
        // control-role gateway rejects any cmd without the `control:`
        // prefix, and rejection shapes differ per role gateway — so
        // rather than pattern-matching the error, retry the whole push
        // once under the control-role key. The endpoint is insert-only
        // and idempotent server-side, so re-sending already-accepted
        // chunks is harmless; a genuinely transient failure just costs
        // one extra attempt before the normal next-launch retry.
        await _pushChunks(gateway, controlCmd, rows);
      }

      await LocalStorage.setSeededTranslationsHash(digest);
    } catch (e) {
      // Silent failure — never user-visible; retried next launch because
      // the fingerprint was not persisted.
      debugPrint('==> translation seed push failure: $e');
    } finally {
      _inFlight = false;
    }
  }

  /// Sends every chunk of [rows] through [gateway] under [seedCmd]. Same
  /// auth posture as the get_mobile_translations fetch: the splash runs
  /// pre-login, so the endpoint is guest-reachable and insert-only
  /// server-side.
  static Future<void> _pushChunks(
    PlatformGateway gateway,
    String seedCmd,
    List<Map<String, String>> rows,
  ) async {
    for (int i = 0; i < rows.length; i += maxRowsPerCall) {
      final chunk = rows.sublist(i, min(i + maxRowsPerCall, rows.length));
      await gateway.call(seedCmd, payload: {'rows': chunk}, requireAuth: false);
    }
  }

  /// Pure candidate computation, ordered (locale, key) so the fingerprint
  /// is stable across launches. Visible for tests.
  static List<Map<String, String>> computeCandidateRows({
    required Map<String, dynamic> servedMap,
    required String? activeLocale,
  }) {
    final Map<String, Map<String, String>> byLocale = {};

    // Active locale: only keys the served map (which is for this locale)
    // does not already contain.
    if (activeLocale != null) {
      final bundled = BundledTranslations.entriesFor(activeLocale);
      if (bundled != null) {
        final target = byLocale[activeLocale] ??= <String, String>{};
        bundled.forEach((key, value) {
          if (!servedMap.containsKey(key)) target[key] = value;
        });
      }
    }

    // English: humanized rows for every key any bundled locale registers.
    // What exists server-side for non-active locales cannot be diffed
    // locally, so these are offered wholesale and the server skips the
    // ones it already has — except when English is the active locale,
    // where the served map is authoritative and diffing is exact.
    final enTarget = byLocale['en'] ??= <String, String>{};
    for (final locale in BundledTranslations.bundledLocales) {
      final bundled = BundledTranslations.entriesFor(locale);
      if (bundled == null) continue;
      for (final key in bundled.keys) {
        if (activeLocale == 'en' && servedMap.containsKey(key)) continue;
        enTarget.putIfAbsent(key, () => AppHelpers.humanizeTrKey(key));
      }
    }

    final rows = <Map<String, String>>[];
    for (final locale in byLocale.keys.toList()..sort()) {
      final entries = byLocale[locale]!;
      for (final key in entries.keys.toList()..sort()) {
        final value = entries[key]!.trim();
        if (value.isEmpty || value.length > maxValueLength) continue;
        rows.add({'locale': locale, 'key': key, 'value': value});
      }
    }
    return rows;
  }

  /// Stable 32-bit FNV-1a fingerprint of the candidate rows plus the app
  /// version, hex-encoded. Collisions only risk skipping (or repeating) a
  /// push — both harmless against an insert-only endpoint.
  static String fingerprint(List<Map<String, String>> rows, String salt) {
    int hash = 0x811c9dc5;
    void mix(String s) {
      for (final unit in s.codeUnits) {
        hash ^= unit;
        hash = (hash * 0x01000193) & 0xFFFFFFFF;
      }
      hash ^= 0x1F; // unit separator between fields
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }

    for (final row in rows) {
      mix(row['locale'] ?? '');
      mix(row['key'] ?? '');
      mix(row['value'] ?? '');
    }
    mix(salt);
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
