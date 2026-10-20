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

// Guards manager mode's answer (1.36.0). launch_sdk's DefaultHomeBridge
// asks the package manager who answers
// Intent("rokct.intent.action.MANAGER").addCategory(CATEGORY_DEFAULT), with
// no data, and turns manager mode on when another app does. The manager app
// answers through an activity-alias this manifest declares for
// app_type.manager only. If the action, the category, the export or the
// data-less filter drift, manager mode silently disappears again, and
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

  group('manager mode entry (app_type.manager host_integration)', () {
    test('declares one alias answering the launcher query exactly', () {
      final entries = appXml('manager')
          .where((e) => e.contains('rokct.intent.action.MANAGER'))
          .toList();
      expect(entries, hasLength(1));
      final alias = entries.single;
      expect(alias, startsWith('<activity-alias '));
      expect(alias, contains('android:name=".RokctManagerEntry"'));
      expect(alias, contains('android:targetActivity=".MainActivity"'));
      expect(alias, contains('android:exported="true"'));
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

    test('only the manager flavor answers manager mode', () {
      for (final flavor in flavors.keys.where((f) => f != 'manager')) {
        expect(
          appXml(flavor).any((e) => e.contains('rokct.intent.action.MANAGER')),
          isFalse,
          reason: '$flavor must not turn on the launcher\'s manager mode',
        );
      }
      final top = manifest['host_integration'] as Map<String, dynamic>?;
      expect(
        jsonEncode(top ?? const {}).contains('rokct.intent.action.MANAGER'),
        isFalse,
      );
    });
  });
}
