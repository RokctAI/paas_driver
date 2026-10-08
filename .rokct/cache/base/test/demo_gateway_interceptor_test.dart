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

// The one demo seam in the HTTP layer: while a demo session is active,
// platform-gateway POSTs answer from <cmd>.json fixtures and never reach
// the network; an unknown cmd fails loudly; outside demo it passes through.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:base_sdk/src/handlers/demo_gateway_interceptor.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';

/// Terminal adapter: records that the network was reached.
class _Network implements HttpClientAdapter {
  int calls = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    calls++;
    return ResponseBody.fromString('{"message":"live"}', 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late bool demo;
  late _Network network;
  late Dio dio;
  final Map<String, String> files = {};

  setUp(() {
    demo = true;
    network = _Network();
    files.clear();
    DemoFixtures.reset();
    DemoFixtures.loader = (key) async => files[key];
    DemoFixtures.registerAssetDirectory('assets/demo/x');
    dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'))
      ..httpClientAdapter = network
      ..interceptors.add(DemoGatewayInterceptor(isDemo: () => demo));
  });

  tearDown(DemoFixtures.reset);

  Future<Response<dynamic>> call(String cmd, [Map<String, dynamic>? p]) =>
      dio.post(kPlatformGatewayPath,
          data: {'cmd': cmd, if (p != null) 'payload': p});

  test('demo: a known cmd answers its fixture without the network', () async {
    files['assets/demo/x/api.x.list.json'] = '[{"name":"a"}]';
    final res = await call('api.x.list');
    expect(res.data, [
      {'name': 'a'}
    ]);
    expect(network.calls, 0);
  });

  test('demo: an unknown cmd is a clear error, not a silent pass', () async {
    await expectLater(
      call('api.x.nope'),
      throwsA(isA<DioException>()
          .having((e) => e.error, 'error', isA<DemoFixtureMissing>())
          .having((e) => e.message, 'message', contains('api.x.nope'))),
    );
    expect(network.calls, 0);
  });

  test('not demo: the call reaches the network untouched', () async {
    demo = false;
    files['assets/demo/x/api.x.list.json'] = '[]';
    final res = await call('api.x.list');
    expect(network.calls, 1);
    expect(res.data, {'message': 'live'});
  });

  test('the switch is read per call, never cached', () async {
    files['assets/demo/x/api.x.list.json'] = '"fixture"';
    expect((await call('api.x.list')).data, 'fixture');
    demo = false;
    expect((await call('api.x.list')).data, {'message': 'live'});
    demo = true;
    expect((await call('api.x.list')).data, 'fixture');
    expect(network.calls, 1);
  });

  test('demo: non-gateway requests pass through', () async {
    await dio.get('/api/v1/method/other');
    expect(network.calls, 1);
  });

  test('\$demo_select picks by payload field and by role, with default',
      () async {
    files['assets/demo/x/api.x.one.json'] =
        '{"\$demo_select":{"by":"payload.course","cases":{"c1":{"p":1}},'
        '"default":null}}';
    files['assets/demo/x/api.x.gate.json'] =
        '{"\$demo_select":{"by":"role","cases":{"admin":{"allowed":true}},'
        '"default":{"allowed":false}}}';
    expect((await call('api.x.one', {'course': 'c1'})).data, {'p': 1});
    expect((await call('api.x.one', {'course': 'c2'})).data, isNull);
    DemoFixtures.role = () => 'admin';
    expect((await call('api.x.gate')).data, {'allowed': true});
    DemoFixtures.role = () => 'student';
    expect((await call('api.x.gate')).data, {'allowed': false});
  });

  test('\$now tokens resolve to the current time', () async {
    files['assets/demo/x/api.x.time.json'] =
        '{"server_epoch_ms":"\$now_ms","at":"\$now_iso"}';
    final before = DateTime.now().millisecondsSinceEpoch;
    final data = (await call('api.x.time')).data as Map;
    expect(data['server_epoch_ms'], greaterThanOrEqualTo(before));
    expect(DateTime.parse(data['at'] as String).isUtc, isTrue);
  });

  test('first registered directory holding the file wins', () async {
    DemoFixtures.registerAssetDirectory('assets/demo/y/');
    files['assets/demo/y/api.x.list.json'] = '"y"';
    expect((await call('api.x.list')).data, 'y');
    files['assets/demo/x/api.x.list.json'] = '"x"';
    expect((await call('api.x.list')).data, 'x');
    expect(DemoFixtures.directories, ['assets/demo/x', 'assets/demo/y']);
  });
}
