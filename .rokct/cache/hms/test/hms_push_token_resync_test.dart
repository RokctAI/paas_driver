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

// The boot hook syncs the HMS token before sign-in, as Guest, which fails.
// It used to be marked synced anyway and was never sent again. Now a failed
// sync leaves it unsynced, and a sign-in (SessionStartHooks) sends it.

import 'dart:convert';
import 'dart:typed_data';

import 'package:base_sdk/base_sdk.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hms_sdk/src/services/hms_push_bootstrap.dart';

class _Adapter implements HttpClientAdapter {
  int status = 401;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(<String, dynamic>{'message': 'ok'}),
      status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _StubHttpService extends HttpService {
  _StubHttpService(this.adapter);

  final _Adapter adapter;

  @override
  Dio client({bool requireAuth = false, bool routing = false}) =>
      Dio()..httpClientAdapter = adapter;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Adapter adapter;

  setUp(() async {
    adapter = _Adapter();
    if (getIt.isRegistered<HttpService>()) {
      await getIt.unregister<HttpService>();
    }
    getIt.registerSingleton<HttpService>(_StubHttpService(adapter));
    await HmsPushBootstrap.instance.reset();
  });

  tearDown(() async {
    await HmsPushBootstrap.instance.reset();
    if (getIt.isRegistered<HttpService>()) {
      await getIt.unregister<HttpService>();
    }
  });

  test('a failed sync is not marked synced', () async {
    adapter.status = 401;
    expect(await HmsPushBootstrap.instance.syncToken('hms-1'), isFalse);
    adapter.status = 200;
    expect(await HmsPushBootstrap.instance.syncToken('hms-1'), isTrue);
  });

  test('a sign-in sends the token the boot sync could not', () async {
    adapter.status = 401;
    HmsPushBootstrap.instance.handleToken('hms-1');
    await pumpEventQueue();
    expect(adapter.requests, hasLength(1));

    adapter.status = 200;
    await HmsPushBootstrap.instance.onSessionStart();
    expect(adapter.requests, hasLength(2));
    final body = (adapter.requests.last.data as Map).cast<String, dynamic>();
    expect(body['cmd'], HmsPushBootstrap.registerDeviceTokenCmd);
    expect(
      (body['payload'] as Map)['device_token'],
      'hms-1',
    );
  });

  test('a sign-in re-sends even an already synced token', () async {
    // The same device token may be registered under the previous account.
    adapter.status = 200;
    HmsPushBootstrap.instance.handleToken('hms-1');
    await pumpEventQueue();
    await HmsPushBootstrap.instance.onSessionStart();
    expect(adapter.requests, hasLength(2));
  });
}
