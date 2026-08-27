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

import 'package:base_sdk/src/models/response/languages_response.dart';
import 'package:base_sdk/src/services/bundled_af_translations.dart';

/// Registry of locally bundled UI-string maps, keyed by locale.
///
/// The backend-served PaaS Translation map (fetched via
/// `api.translation.get_mobile_translations` and cached in LocalStorage)
/// always wins: [lookup] is only consulted by `AppHelpers.getTranslation`
/// for keys the served map does not contain, before the humanized-key
/// fallback. Locales with no bundled map (everything except `af` today)
/// behave exactly as before this registry existed.
///
/// base_sdk seeds its own Afrikaans map. Feature SDKs contribute the
/// Afrikaans values for their manifest-declared tr_keys by calling
/// [register] from a composed `boot_hooks` entry in their manifest.json —
/// the same compose-time registration pattern DI/boot wiring already uses.
class BundledTranslations {
  BundledTranslations._();

  /// Human-readable titles for bundled locales, used when the backend
  /// language list is unreachable and the picker falls back to
  /// [fallbackLanguages]. All bundled locales are left-to-right
  /// (`backward: false`).
  static const Map<String, String> _localeTitles = {
    'en': 'English',
    'af': 'Afrikaans',
  };

  static final Map<String, Map<String, String>> _byLocale = {
    'af': Map<String, String>.of(kBaseAfTranslations),
  };

  /// Merges [entries] into the bundled map for [locale]. Later
  /// registrations win on key collisions, mirroring how the composed
  /// TrKeys block is regenerated from every installed SDK's manifest.
  static void register(String locale, Map<String, String> entries) {
    (_byLocale[locale] ??= <String, String>{}).addAll(entries);
  }

  /// The bundled value for [key] in [locale], or null when either the
  /// locale has no bundled map or the map does not contain the key.
  static String? lookup(String? locale, String key) {
    if (locale == null) return null;
    return _byLocale[locale]?[key];
  }

  /// Locales that ship a non-empty bundled map ('en' is implicit — English
  /// survives through the humanized-key fallback and the served map).
  static List<String> get bundledLocales =>
      _byLocale.entries.where((e) => e.value.isNotEmpty).map((e) => e.key).toList()
        ..sort();

  /// Static language list used ONLY when fetching the backend language
  /// list fails (offline / unreachable / error response): English plus
  /// every locale with a bundled map. A successful backend response stays
  /// authoritative — this list is never merged into one.
  static List<LanguageData> fallbackLanguages() {
    final locales = <String>['en', ...bundledLocales.where((l) => l != 'en')];
    return [
      for (final locale in locales)
        LanguageData(
          id: 'local-$locale',
          title: _localeTitles[locale] ?? locale,
          locale: locale,
          backward: false,
          isDefault: locale == 'en',
          active: true,
        ),
    ];
  }
}
