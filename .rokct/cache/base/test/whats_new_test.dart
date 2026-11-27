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

import 'dart:convert';
import 'dart:typed_data';

import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/whats_new.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Bundle extends CachingAssetBundle {
  final String? body;
  _Bundle(this.body);
  @override
  Future<ByteData> load(String key) async {
    if (body == null || key != WhatsNew.asset) throw FlutterError('missing');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(body!)));
  }
}

String _note(String v) => jsonEncode({'version': v, 'notes': 'Faster lessons.'});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  test('no packed note shows nothing', () async {
    expect(await WhatsNew.due(bundle: _Bundle(null), build: '1'), isNull);
  });

  test('fresh install records the version and shows nothing', () async {
    expect(await WhatsNew.due(bundle: _Bundle(_note('2.8.13')), build: '1'), isNull);
    expect(LocalStorage.getJson(WhatsNew.storageKey)?['seen'], '2.8.13+1');
  });

  test('an update shows its own note once', () async {
    await WhatsNew.due(bundle: _Bundle(_note('2.8.12')), build: '1');
    final note = await WhatsNew.due(bundle: _Bundle(_note('2.8.13')), build: '1');
    expect(note?.version, '2.8.13');
    expect(note?.notes, 'Faster lessons.');
    expect(await WhatsNew.due(bundle: _Bundle(_note('2.8.13')), build: '1'), isNull);
  });

  test('a rebuild of the same version shows its note once', () async {
    await WhatsNew.due(bundle: _Bundle(_note('2.8.12')), build: '1');
    await WhatsNew.due(bundle: _Bundle(_note('2.8.13')), build: '2');
    expect(await WhatsNew.due(bundle: _Bundle(_note('2.8.13')), build: '3'),
        isNotNull);
    expect(await WhatsNew.due(bundle: _Bundle(_note('2.8.13')), build: '3'),
        isNull);
  });
}
