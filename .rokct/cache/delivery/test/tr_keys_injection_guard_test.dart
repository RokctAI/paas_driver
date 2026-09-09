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


// Guards the standalone harness against TrKeys injection drift (the
// merchants_sdk / lms_sdk tr_keys_injection_guard_test pattern).
//
// This SDK's TrKeys entries live in `manifest.json` — at the top level and
// inside the app_type flavor block (driver) — and are injected into the
// host's base_sdk `TrKeys` at compose time. Standalone,
// `tool/inject_tr_keys.dart` performs the same injection into the
// resolved base_sdk checkout (all flavors' keys, a harmless superset).
//
// This test reads both sides from disk and fails with the exact
// regeneration command whenever the resolved base_sdk is missing a
// manifest key — ONE actionable failure instead of hundreds of
// undefined-getter compile errors taking down the whole driver suite.
//
// Deliberately imports nothing from delivery_sdk: it must still load
// when the rest of the suite cannot compile.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'resolved base_sdk TrKeys carries every manifest tr_key '
      '(else run: dart run tool/inject_tr_keys.dart)', () {
    final manifest = jsonDecode(File('manifest.json').readAsStringSync())
        as Map<String, dynamic>;
    final trKeys = <String, String>{};
    (manifest['tr_keys'] as Map<String, dynamic>? ?? {})
        .forEach((k, v) => trKeys[k] = v as String);
    final appType = manifest['app_type'] as Map<String, dynamic>? ?? {};
    for (final flavor in appType.values) {
      if (flavor is Map<String, dynamic>) {
        (flavor['tr_keys'] as Map<String, dynamic>? ?? {})
            .forEach((k, v) => trKeys[k] = v as String);
      }
    }
    expect(trKeys, isNotEmpty,
        reason: 'manifest.json is expected to declare tr_keys');

    final packageConfigFile = File('.dart_tool/package_config.json');
    final packageConfig = jsonDecode(packageConfigFile.readAsStringSync())
        as Map<String, dynamic>;
    final baseSdk = (packageConfig['packages'] as List)
        .cast<Map>()
        .firstWhere((p) => p['name'] == 'base_sdk');
    final rootUriRaw = baseSdk['rootUri'] as String;
    final rootUri =
        Uri.parse(rootUriRaw.endsWith('/') ? rootUriRaw : '$rootUriRaw/');
    final baseSdkRootUri = rootUri.isAbsolute
        ? rootUri
        : packageConfigFile.absolute.parent.uri.resolveUri(rootUri);
    final src =
        File.fromUri(baseSdkRootUri.resolve('lib/src/services/tr_keys.dart'))
            .readAsStringSync();

    // A TrKeys member may come from the injected marker block or be
    // declared by base itself (in which case the installer keeps base's
    // declaration and skips the SDK's — same rule
    // tool/inject_tr_keys.dart applies).
    final declared = RegExp(r'static const String (\w+)\s*=')
        .allMatches(src)
        .map((m) => m.group(1))
        .toSet();
    final missing =
        trKeys.keys.where((k) => !declared.contains(k)).toList()..sort();

    expect(
      missing,
      isEmpty,
      reason: 'The resolved base_sdk TrKeys is missing '
          '${missing.length} key(s) declared in manifest.json '
          '(first few: ${missing.take(5).join(', ')}). '
          'Re-run the standalone injection from delivery/dart:\n'
          '  dart run tool/inject_tr_keys.dart\n'
          'This regenerates the @sdk-tr-keys block from manifest.json — '
          'never add keys to TrKeys by hand.',
    );
  });

  test('every TrKeys member this SDK references is declared by the '
      'manifest or by base_sdk itself', () {
    final manifest = jsonDecode(File('manifest.json').readAsStringSync())
        as Map<String, dynamic>;
    final manifestKeys = <String>{
      ...(manifest['tr_keys'] as Map<String, dynamic>? ?? {}).keys,
    };
    final appType = manifest['app_type'] as Map<String, dynamic>? ?? {};
    for (final flavor in appType.values) {
      if (flavor is Map<String, dynamic>) {
        manifestKeys
            .addAll((flavor['tr_keys'] as Map<String, dynamic>? ?? {}).keys);
      }
    }

    final packageConfigFile = File('.dart_tool/package_config.json');
    final packageConfig = jsonDecode(packageConfigFile.readAsStringSync())
        as Map<String, dynamic>;
    final baseSdk = (packageConfig['packages'] as List)
        .cast<Map>()
        .firstWhere((p) => p['name'] == 'base_sdk');
    final rootUriRaw = baseSdk['rootUri'] as String;
    final rootUri =
        Uri.parse(rootUriRaw.endsWith('/') ? rootUriRaw : '$rootUriRaw/');
    final baseSdkRootUri = rootUri.isAbsolute
        ? rootUri
        : packageConfigFile.absolute.parent.uri.resolveUri(rootUri);
    final baseSrc =
        File.fromUri(baseSdkRootUri.resolve('lib/src/services/tr_keys.dart'))
            .readAsStringSync();
    final baseDeclared = RegExp(r'static const String (\w+)\s*=')
        .allMatches(baseSrc)
        .map((m) => m.group(1)!)
        .toSet();

    final reference = RegExp(r'TrKeys\.([A-Za-z0-9_]+)');
    final referenced = <String>{};
    for (final dir in const ['lib', 'templates', 'test']) {
      final directory = Directory(dir);
      if (!directory.existsSync()) continue;
      for (final entity in directory.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        for (final match in reference.allMatches(entity.readAsStringSync())) {
          referenced.add(match.group(1)!);
        }
      }
    }
    expect(referenced, isNotEmpty,
        reason: 'this SDK is expected to reference TrKeys members');

    final undeclared = referenced
        .where((k) => !manifestKeys.contains(k) && !baseDeclared.contains(k))
        .toList()
      ..sort();

    expect(
      undeclared,
      isEmpty,
      reason: 'These TrKeys members are referenced by delivery_sdk source '
          'but are declared neither in this package\'s manifest.json '
          '`tr_keys` nor by base_sdk itself, so a composed host would not '
          'declare them: ${undeclared.join(', ')}. Add each one to '
          'manifest.json `tr_keys` (top level, or the app_type flavor that '
          'uses it) — that map is the single source of truth the composer '
          'and tool/inject_tr_keys.dart both read.',
    );
  });
}
