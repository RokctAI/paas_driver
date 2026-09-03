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

// Frame 49l's commerce seam, from this side: the two manifest
// `integrations` entries that put ManagerWalletPane on the manager hub
// (merchants_sdk >= 1.25.0's restaurant page carries the markers; its
// test/hub_markers_test.dart pins the same strings and simulates the
// installer's insert). The installer replaces EVERY occurrence of a
// placeholder by substring, so the pair's shape — column-0 imports marker,
// indented widget marker that is NOT a substring of it — is load-bearing,
// and every symbol the widget replacement names outside the host page
// must be on this SDK's barrel.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String target =
    'lib/presentation/pages/manager/restaurant/restaurant_page.dart';

const String importsPlaceholder = '// @revenue-manager-wallet-imports';
const String importsReplacement =
    "import 'package:revenue_sdk/revenue_sdk.dart';";
const String walletPlaceholder = '      // @revenue-manager-wallet';
const String walletReplacement = '      ManagerWalletPane(\n'
    '        scope: ManagerWalletScope(\n'
    '          shopId: merchantWalletScope(ref).shopId,\n'
    '          shopName: merchantWalletScope(ref).shopName,\n'
    '        ),\n'
    '      ),';

Map<String, dynamic> _manifest() =>
    jsonDecode(File('manifest.json').readAsStringSync()) as Map<String, dynamic>;

List<Map<String, dynamic>> _integrations() =>
    ((_manifest()['integrations'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();

void main() {
  test('the manifest declares exactly the two hub entries, byte for byte', () {
    final entries = _integrations();
    expect(entries.length, 2);
    for (final e in entries) {
      expect(e['target'], target);
    }
    final imports = entries.singleWhere((e) => e['placeholder'] == importsPlaceholder);
    expect(imports['replacement'], importsReplacement);
    final wallet = entries.singleWhere((e) => e['placeholder'] == walletPlaceholder);
    expect(wallet['replacement'], walletReplacement);
  });

  test('the widget placeholder keeps its indent and is not inside the imports one', () {
    expect(walletPlaceholder.startsWith('      //'), isTrue);
    expect(importsPlaceholder.contains(walletPlaceholder), isFalse);
    expect(walletPlaceholder.contains(importsPlaceholder), isFalse);
    // The bare text IS a prefix of the imports marker: that is why the
    // indent is part of the contract.
    expect(importsPlaceholder.startsWith(walletPlaceholder.trim()), isTrue);
  });

  test('the widget replacement is a closed list element naming only barrel symbols',
      () {
    expect(walletReplacement.endsWith('),'), isTrue);
    expect('('.allMatches(walletReplacement).length,
        ')'.allMatches(walletReplacement).length);
    final barrel = File('lib/revenue_sdk.dart').readAsStringSync();
    final exported = <String>{};
    for (final m in RegExp(r"export '([^']+)';").allMatches(barrel)) {
      exported.add(File('lib/${m.group(1)!}').readAsStringSync());
    }
    for (final symbol in ['class ManagerWalletPane', 'class ManagerWalletScope']) {
      expect(exported.any((s) => s.contains(symbol)), isTrue,
          reason: '$symbol must be reachable from package:revenue_sdk/revenue_sdk.dart');
    }
    // merchantWalletScope(ref) is the host page's own seam; nothing else
    // outside base is named.
    expect(walletReplacement, contains('merchantWalletScope(ref)'));
  });

  test('the manifest version carries the entries (1.11.1 or later)', () {
    final version = _manifest()['version'] as String;
    final parts = version.split('.').map(int.parse).toList();
    expect(parts.length, 3);
    expect(parts[0] > 1 || (parts[0] == 1 && (parts[1] > 11 || (parts[1] == 11 && parts[2] >= 1))),
        isTrue, reason: 'revenue_sdk $version predates the hub seam');
  });
}
