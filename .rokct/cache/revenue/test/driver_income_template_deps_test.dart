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

// The templates reach the composed app's dependency graph only through this
// package.
//
// `templates/` is excluded from analysis (analysis_options.yaml) and compiles
// in the HOST package after install, so an import the host cannot resolve is
// invisible here and fatal there. That is exactly what shipped: the driver
// income template imported charts_flutter, which neither this pubspec nor
// the generated host pubspec (core/base/dart/templates/pubspec.yaml)
// declared - it only ever resolved on hosts that pinned it by hand. The
// guard is structural: every `package:` a template imports must be declared
// in this pubspec's `dependencies`, be the SDK itself, the Flutter SDK, or a
// named composition peer the manager income page resolves in a composed
// manager host (merchants_sdk, products_sdk - installed alongside by the
// same profile, never depended on directly, per ADR-005).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Top-level keys of the `dependencies:` block, parsed without a yaml
/// dependency: the block runs from `dependencies:` to the next unindented
/// line, and each direct dependency is a two-space-indented `name:` line.
Set<String> _pubspecDependencies() {
  final lines = File('pubspec.yaml').readAsLinesSync();
  final start = lines.indexWhere((l) => l.trim() == 'dependencies:');
  expect(start, isNot(-1), reason: 'pubspec.yaml has no dependencies block');
  final keys = <String>{};
  final direct = RegExp(r'^  ([a-z0-9_]+):');
  for (final line in lines.skip(start + 1)) {
    if (line.isNotEmpty && !line.startsWith(' ') && !line.startsWith('#')) {
      break;
    }
    final m = direct.firstMatch(line);
    if (m != null) keys.add(m.group(1)!);
  }
  return keys;
}

/// Every `package:<name>/` a Dart file under templates/ imports, by file.
Map<String, Set<String>> _templateImports() {
  final imports = RegExp("^import 'package:([a-z0-9_]+)/", multiLine: true);
  final byFile = <String, Set<String>>{};
  for (final entity in Directory('templates').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final found = imports
        .allMatches(entity.readAsStringSync())
        .map((m) => m.group(1)!)
        .toSet();
    if (found.isNotEmpty) byFile[entity.path] = found;
  }
  return byFile;
}

void main() {
  const self = {'revenue_sdk', 'flutter'};
  const compositionPeers = {'merchants_sdk', 'products_sdk'};

  group('templates resolve against this pubspec', () {
    test('the driver income chart dependency is declared here', () {
      expect(
        _pubspecDependencies(),
        contains('charts_flutter'),
        reason: 'templates/pages/driver/income/income_page.dart imports '
            'charts_flutter and the generated host pubspec does not carry it',
      );
    });

    test('every package a template imports is declared or a named peer', () {
      final allowed = {..._pubspecDependencies(), ...self, ...compositionPeers};
      final byFile = _templateImports();
      expect(byFile, isNotEmpty, reason: 'no templates found to check');
      for (final entry in byFile.entries) {
        final missing = entry.value.difference(allowed);
        expect(
          missing,
          isEmpty,
          reason: '${entry.key} imports ${missing.join(', ')}, which this '
              'pubspec does not declare - the host cannot resolve it',
        );
      }
    });
  });
}
