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

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// templates/main.dart is copied into every composed app and is excluded from
// analysis, so this pins the release-mode debugPrint guard by source.
void main() {
  final String src = File('templates/main.dart').readAsStringSync();
  final String body = src.substring(src.indexOf('void main() async {'));

  test('release builds silence debugPrint before any boot hook', () {
    final int guard = body.indexOf(
        'if (kReleaseMode) {\n    debugPrint = (String? message, {int? wrapWidth}) {};');
    expect(guard, greaterThan(0));
    expect(guard, lessThan(body.indexOf('@generated-boot-hooks-start')));
    expect(guard, lessThan(body.indexOf('runApp(')));
  });

  test('crash handlers keep the original printer', () {
    expect(body.indexOf('final DebugPrintCallback crashLog = debugPrint;'),
        lessThan(body.indexOf('if (kReleaseMode)')));
    expect(body, contains("crashLog('Uncaught Flutter error:"));
    expect(body, contains("crashLog('Uncaught platform error:"));
  });
}
