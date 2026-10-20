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

// Guards driver mode's answer (1.30.0). launch_sdk's DefaultHomeBridge
// asks the package manager who answers
// Intent("rokct.intent.action.DRIVER").addCategory(CATEGORY_DEFAULT), with
// no data, and turns driver mode on when another app does. The driver app
// answers through an activity-alias this manifest declares for
// app_type.driver only. If the action, the category, the export or the
// data-less filter drift, driver mode silently disappears again, and
// nothing else in this package would fail.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final manifest = jsonDecode(File('manifest.json').readAsStringSync())
      as Map<String, dynamic>;
  final flavors = manifest['app_type'] as Map<String, dynamic>;

  List<String> appXml(String flavor) {
    final block = flavors[flavor] as Map<String, dynamic>? ?? const {};
    final hi = block['host_integration'] as Map<String, dynamic>? ?? const {};
    return ((hi['android_application_xml'] as List?) ?? const [])
        .cast<String>()
        .toList();
  }

  group('driver mode entry (app_type.driver host_integration)', () {
    test('declares one alias answering the launcher query exactly', () {
      final entries = appXml('driver')
          .where((e) => e.contains('rokct.intent.action.DRIVER'))
          .toList();
      expect(entries, hasLength(1));
      final alias = entries.single;
      expect(alias, startsWith('<activity-alias '));
      expect(alias, contains('android:name=".RokctDriverEntry"'));
      expect(alias, contains('android:targetActivity=".MainActivity"'));
      expect(alias, contains('android:exported="true"'));
      expect(
        alias,
        contains('<action android:name="rokct.intent.action.DRIVER" />'),
      );
      expect(
        alias,
        contains(
          '<category android:name="android.intent.category.DEFAULT" />',
        ),
      );
      // The launcher's query intent carries no data; a filter with a <data>
      // element would not match it.
      expect(alias, isNot(contains('<data ')));
      expect(alias, contains('io.flutter.embedding.android.NormalTheme'));
    });

    test('only the driver flavor answers driver mode', () {
      for (final flavor in flavors.keys.where((f) => f != 'driver')) {
        expect(
          appXml(flavor).any((e) => e.contains('rokct.intent.action.DRIVER')),
          isFalse,
          reason: '$flavor must not turn on the launcher\'s driver mode',
        );
      }
      final top = manifest['host_integration'] as Map<String, dynamic>?;
      expect(
        jsonEncode(top ?? const {}).contains('rokct.intent.action.DRIVER'),
        isFalse,
      );
    });
  });
}
