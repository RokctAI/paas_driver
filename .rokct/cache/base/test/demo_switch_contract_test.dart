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


// Source contract for the demo switch. AppConstants.isDemo is the
// compile-time half (the guided tour's flag); DemoSession.demoActive is
// the one question every demo seam asks - the build flag OR the runtime
// session. A seam that reads the constant directly would serve a
// server-marked demo account the real repositories, silently. So: no
// source file in any Dart package of this repo may read
// `AppConstants.isDemo` except the two that define the switch.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Where the constant may still be read, relative to the repo root.
///
/// * `app_constants.dart` defines it (`static const bool isDemo`).
/// * `demo_session.dart` is the OR: `demoActive => isDemo || active`.
const Set<String> _deliberatelyKept = {
  'base/dart/lib/src/constants/app_constants.dart',
  'base/dart/lib/src/services/demo_session.dart',
};

final RegExp _read = RegExp(r'\bAppConstants\.isDemo\b');

/// The repo root: the nearest ancestor of the working directory that holds
/// this package's manifest under `base/dart/`. `flutter test` runs with
/// the package root as its working directory, so this is two levels up.
Directory _repoRoot() {
  var dir = Directory.current.absolute;
  while (true) {
    if (File('${dir.path}/base/dart/manifest.json').existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      fail('repo root (a directory holding base/dart/manifest.json) not '
          'found above ${Directory.current.path}');
    }
    dir = parent;
  }
}

/// Every Dart source the packages ship or install: `<sdk>/dart/lib` and
/// `<sdk>/dart/templates`, for every SDK directory in the repo.
Iterable<File> _sources(Directory root) sync* {
  for (final sdk in root.listSync().whereType<Directory>()) {
    for (final sub in const ['lib', 'templates']) {
      final dir = Directory('${sdk.path}/dart/$sub');
      if (!dir.existsSync()) continue;
      yield* dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
    }
  }
}

/// True when [line] reads the constant in code - comments do not count,
/// a doc comment naming `[AppConstants.isDemo]` is documentation.
bool _readsInCode(String line) {
  final trimmed = line.trimLeft();
  if (trimmed.startsWith('//')) return false;
  final comment = line.indexOf('//');
  final code = comment < 0 ? line : line.substring(0, comment);
  return _read.hasMatch(code);
}

void main() {
  test('no Dart source reads AppConstants.isDemo outside the switch itself',
      () {
    final root = _repoRoot();
    final readers = <String>{};
    for (final file in _sources(root)) {
      final relative = file.path.substring(root.path.length + 1);
      if (file.readAsLinesSync().any(_readsInCode)) readers.add(relative);
    }

    // The OR must still read the constant - that is the build-time half.
    expect(readers, contains('base/dart/lib/src/services/demo_session.dart'));
    // And nothing else may.
    expect(readers.difference(_deliberatelyKept), isEmpty,
        reason: 'read DemoSession.demoActive instead (a demo build OR a '
            'demo session), and listen on DemoSession.instance where the '
            'answer is registered or drawn once');
  });

  test('the compile-time half is still defined where it always was', () {
    final root = _repoRoot();
    final source =
        File('${root.path}/base/dart/lib/src/constants/app_constants.dart')
            .readAsStringSync();
    expect(source, contains('static const bool isDemo'));
  });
}
