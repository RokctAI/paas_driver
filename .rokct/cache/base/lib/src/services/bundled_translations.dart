// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

import 'package:base_sdk/src/models/response/languages_response.dart';
import 'package:base_sdk/src/services/bundled_af_translations.dart';
import 'package:base_sdk/src/services/bundled_en_translations.dart';

/// Registry of locally bundled UI-string maps, keyed by locale.
///
/// The backend-served PaaS Translation map (fetched via
/// `api.translation.get_mobile_translations` and cached in LocalStorage)
/// always wins: [lookup] is only consulted by `AppHelpers.getTranslation`
/// for keys the served map does not contain, before the humanized-key
/// fallback. Locales with no bundled map (everything except `en` and `af`
/// today) behave exactly as before this registry existed.
///
/// base_sdk seeds its own Afrikaans map and a small English map: the
/// English rows cover only the keys whose humanized form is NOT their copy
/// (`maintenance_title` humanizes to "Maintenance title"), since English
/// otherwise survives through `AppHelpers.humanizeTrKey`. Feature SDKs
/// contribute the values for their manifest-declared tr_keys by calling
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
    'en': Map<String, String>.of(kBaseEnTranslations),
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

  /// An immutable snapshot of the bundled map for [locale], or null when
  /// the locale has no (non-empty) bundled map. Consumed by
  /// TranslationSeeder to compute the candidate rows it offers the
  /// backend.
  static Map<String, String>? entriesFor(String locale) {
    final map = _byLocale[locale];
    if (map == null || map.isEmpty) return null;
    return Map<String, String>.unmodifiable(map);
  }

  /// Locales that ship a non-empty bundled map, sorted. Includes 'en' now
  /// that the kernel bundles English rows for the keys whose humanized
  /// form is not their copy; [fallbackLanguages] still lists English once.
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
