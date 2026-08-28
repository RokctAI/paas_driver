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

import 'package:flutter_test/flutter_test.dart';

import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/bundled_translations.dart';
import 'package:base_sdk/src/common/translation_seeder.dart';

/// Contract under test — the candidate set the seeder offers the
/// (insert-only) backend endpoint:
///
///   * active-locale rows are diffed against the served map (the only
///     locale that CAN be diffed locally);
///   * an `en` row is offered for every key any bundled locale registers,
///     valued with AppHelpers.humanizeTrKey — i.e. exactly what the UI's
///     last-resort fallback renders — and diffed only when `en` is the
///     active locale;
///   * output is (locale, key)-sorted so the persisted fingerprint is
///     stable across launches;
///   * the fingerprint changes when any row or the salt changes.
void main() {
  Map<String, String> rowsFor(
    List<Map<String, String>> rows,
    String locale,
  ) {
    return {
      for (final row in rows)
        if (row['locale'] == locale) row['key']!: row['value']!,
    };
  }

  group('TranslationSeeder.computeCandidateRows', () {
    test('diffs the active locale against the served map', () {
      final af = BundledTranslations.entriesFor('af')!;
      final servedKey = af.keys.first;
      final missingKey = af.keys.skip(1).first;

      final rows = TranslationSeeder.computeCandidateRows(
        servedMap: {servedKey: 'reeds bedien'},
        activeLocale: 'af',
      );

      final afRows = rowsFor(rows, 'af');
      expect(afRows.containsKey(servedKey), isFalse);
      expect(afRows[missingKey], af[missingKey]);
    });

    test('offers humanized en rows for every bundled key, undiffed when '
        'en is not the active locale', () {
      final af = BundledTranslations.entriesFor('af')!;
      final servedKey = af.keys.first;

      final rows = TranslationSeeder.computeCandidateRows(
        servedMap: {servedKey: 'reeds bedien'},
        activeLocale: 'af',
      );

      final enRows = rowsFor(rows, 'en');
      // The served map is Afrikaans — it says nothing about what exists
      // server-side for en, so en rows are offered wholesale.
      expect(enRows[servedKey], AppHelpers.humanizeTrKey(servedKey));
      for (final key in af.keys.take(20)) {
        expect(enRows[key], AppHelpers.humanizeTrKey(key));
      }
    });

    test('diffs en rows when en IS the active locale', () {
      final af = BundledTranslations.entriesFor('af')!;
      final servedKey = af.keys.first;

      final rows = TranslationSeeder.computeCandidateRows(
        servedMap: {servedKey: 'Already served'},
        activeLocale: 'en',
      );

      final enRows = rowsFor(rows, 'en');
      expect(enRows.containsKey(servedKey), isFalse);
    });

    test('is (locale, key)-sorted for a stable fingerprint', () {
      final rows = TranslationSeeder.computeCandidateRows(
        servedMap: const {},
        activeLocale: 'af',
      );
      final ordered = [
        for (final row in rows) '${row['locale']}${row['key']}',
      ];
      final sorted = [...ordered]..sort();
      expect(ordered, sorted);
    });

    test('humanizeTrKey renders dots/underscores as spaces with a leading '
        'capital', () {
      expect(AppHelpers.humanizeTrKey('add.storeis'), 'Add storeis');
      expect(
        AppHelpers.humanizeTrKey('do_you_want_to_delete_it?'),
        'Do you want to delete it?',
      );
    });

    test('humanizeTrKey breaks camelCase into lower-cased words (the raw '
        'key must never leak into the UI)', () {
      // The exact bug on show in the profile footer: the year key's
      // camelCase value fell through untouched as "DaysInAppThisYear".
      expect(
        AppHelpers.humanizeTrKey('daysInAppThisYear'),
        'Days in app this year',
      );
      expect(AppHelpers.humanizeTrKey('goodAfternoon'), 'Good afternoon');
      // Words already separated keep their own capitalization: only a
      // lowercase/digit-to-uppercase boundary is a camelCase break.
      expect(AppHelpers.humanizeTrKey('good.Morning'), 'Good Morning');
      expect(AppHelpers.humanizeTrKey('Save.for.Later'), 'Save for Later');
    });
  });

  group('TranslationSeeder.fingerprint', () {
    test('is stable for equal input and sensitive to rows and salt', () {
      final rows = [
        {'locale': 'en', 'key': 'a.b', 'value': 'A b'},
        {'locale': 'en', 'key': 'c.d', 'value': 'C d'},
      ];
      final same = [
        {'locale': 'en', 'key': 'a.b', 'value': 'A b'},
        {'locale': 'en', 'key': 'c.d', 'value': 'C d'},
      ];
      final changed = [
        {'locale': 'en', 'key': 'a.b', 'value': 'A b!'},
        {'locale': 'en', 'key': 'c.d', 'value': 'C d'},
      ];

      expect(
        TranslationSeeder.fingerprint(rows, '1.0.0+1'),
        TranslationSeeder.fingerprint(same, '1.0.0+1'),
      );
      expect(
        TranslationSeeder.fingerprint(rows, '1.0.0+1'),
        isNot(TranslationSeeder.fingerprint(changed, '1.0.0+1')),
      );
      expect(
        TranslationSeeder.fingerprint(rows, '1.0.0+1'),
        isNot(TranslationSeeder.fingerprint(rows, '1.0.1+2')),
      );
    });
  });
}
