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

// Telemetry tracked offline used to be lost: TelemetryClient made one
// gateway POST and swallowed the failure. TelemetrySpool keeps it on the
// device and sends it, in batches, once the backend can be reached.

import 'dart:async';

import 'package:base_sdk/base_sdk.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telemetry_sdk/telemetry_sdk.dart';

class _MemoryStore implements TelemetrySpoolStore {
  Map<String, dynamic>? record;
  int writes = 0;

  @override
  Map<String, dynamic>? read() => record;

  @override
  Future<void> write(Map<String, dynamic>? value) async {
    writes++;
    record = value;
  }
}

class _Call {
  _Call(this.cmd, this.payload);
  final String cmd;
  final Map<String, dynamic> payload;
}

DioException _network() => DioException(
      requestOptions: RequestOptions(path: kPlatformGatewayPath),
      type: DioExceptionType.connectionError,
    );

DioException _status(int code) => DioException(
      requestOptions: RequestOptions(path: kPlatformGatewayPath),
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: kPlatformGatewayPath),
        statusCode: code,
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MemoryStore store;
  late List<_Call> sent;
  late bool online;
  late Object? Function(String cmd) failWith;

  TelemetrySpool spool({int batchSize = 20, int maxQueued = 500}) =>
      TelemetrySpool(
        store: store,
        isOnline: () async => online,
        batchSize: batchSize,
        maxQueued: maxQueued,
        send: (cmd, payload) async {
          final Object? error = failWith(cmd);
          if (error != null) throw error;
          sent.add(_Call(cmd, payload));
        },
      );

  setUp(() {
    store = _MemoryStore();
    sent = <_Call>[];
    online = true;
    failWith = (_) => null;
  });

  tearDown(() => TelemetryClient.configure());

  test('online events are sent straight away and nothing is queued',
      () async {
    final s = spool();
    await s.deliver(TelemetryClient.trackCmd, <String, dynamic>{'event': 'a'});
    expect(sent.single.cmd, TelemetryClient.trackCmd);
    expect(s.pending, 0);
    expect(store.record, isNull);
  });

  test('offline TelemetryClient.track is queued, then flushed when online',
      () async {
    final s = spool();
    TelemetryClient.configure(transport: s.deliver);
    online = false;

    final bool handedOff =
        await TelemetryClient.I.track('app_open', properties: {'n': 1});

    expect(handedOff, isTrue);
    expect(sent, isEmpty);
    expect(s.pending, 1);
    final List<dynamic> events = store.record!['events'] as List<dynamic>;
    expect((events.single as Map)['cmd'], TelemetryClient.trackCmd);

    online = true;
    await s.flush();

    expect(s.pending, 0);
    expect(store.record, isNull);
    expect(sent.single.cmd, TelemetryClient.trackCmd);
    expect(sent.single.payload['event'], 'app_open');
    // The original payload, including the recorded timestamp, is kept.
    expect(sent.single.payload['context'], contains('"timestamp"'));
  });

  test('a network failure while online queues the event', () async {
    final s = spool();
    failWith = (_) => _network();
    await s.deliver(TelemetryClient.cmd, <String, dynamic>{'x': 1});
    expect(s.pending, 1);

    failWith = (_) => null;
    await s.flush();
    expect(sent.single.cmd, TelemetryClient.cmd);
    expect(s.pending, 0);
  });

  test('a rejection is rethrown so the client falls back to control:',
      () async {
    final s = spool();
    TelemetryClient.configure(transport: s.deliver);
    failWith = (cmd) => cmd == TelemetryClient.trackCmd ? _status(417) : null;

    final bool ok = await TelemetryClient.I.track('e');

    expect(ok, isTrue);
    expect(sent.single.cmd, TelemetryClient.controlTrackCmd);
    expect(s.pending, 0);
  });

  test('flush sends in batches and saves after each batch', () async {
    final s = spool(batchSize: 2);
    online = false;
    for (var i = 0; i < 5; i++) {
      await s.deliver(TelemetryClient.trackCmd, <String, dynamic>{'i': i});
    }
    final int writesBefore = store.writes;
    online = true;

    await s.flush();

    expect(sent.map((c) => c.payload['i']), <int>[0, 1, 2, 3, 4]);
    expect(store.writes - writesBefore, 3); // 2 + 2 + 1
    expect(store.record, isNull);
  });

  test('flush stops on a network failure and keeps the rest', () async {
    final s = spool(batchSize: 2);
    online = false;
    for (var i = 0; i < 4; i++) {
      await s.deliver(TelemetryClient.trackCmd, <String, dynamic>{'i': i});
    }
    online = true;
    var calls = 0;
    failWith = (_) => ++calls > 1 ? _network() : null;

    await s.flush();

    expect(sent.map((c) => c.payload['i']), <int>[0]);
    expect(s.pending, 3);
  });

  test('a signed-out flush (401) keeps the queue for later', () async {
    final s = spool();
    online = false;
    await s.deliver(TelemetryClient.trackCmd, <String, dynamic>{'i': 0});
    online = true;
    failWith = (_) => _status(401);

    await s.flush();

    expect(s.pending, 1);
  });

  test('queued tenant cmds rejected by the site go to the control twin',
      () async {
    final s = spool();
    online = false;
    await s.deliver(TelemetryClient.cmd, <String, dynamic>{'e': 1});
    online = true;
    failWith = (cmd) => cmd == TelemetryClient.cmd ? _status(417) : null;

    await s.flush();

    expect(sent.single.cmd, TelemetryClient.controlCmd);
    expect(s.pending, 0);
  });

  test('an event rejected under both cmds is dropped, not retried forever',
      () async {
    final s = spool();
    online = false;
    await s.deliver(TelemetryClient.trackCmd, <String, dynamic>{'e': 1});
    online = true;
    failWith = (_) => _status(417);

    await s.flush();

    expect(s.pending, 0);
  });

  test('the queue survives a restart (new spool, same store)', () async {
    online = false;
    await spool()
        .deliver(TelemetryClient.trackCmd, <String, dynamic>{'e': 'kept'});
    online = true;

    final restarted = spool();
    expect(restarted.pending, 1);
    await restarted.flush();
    expect(sent.single.payload['e'], 'kept');
  });

  test('the queue is capped, oldest dropped first', () async {
    final s = spool(maxQueued: 3);
    online = false;
    for (var i = 0; i < 5; i++) {
      await s.deliver(TelemetryClient.trackCmd, <String, dynamic>{'i': i});
    }
    online = true;
    await s.flush();
    expect(sent.map((c) => c.payload['i']), <int>[2, 3, 4]);
  });

  test('connectivity coming back flushes the queue', () async {
    final s = spool();
    online = false;
    await s.deliver(TelemetryClient.trackCmd, <String, dynamic>{'e': 1});
    final changes = StreamController<List<ConnectivityResult>>();
    s.start(connectivityChanges: changes.stream);
    await pumpEventQueue();
    // Offline at start: the start flush sends nothing.
    expect(sent, isEmpty);

    changes.add(<ConnectivityResult>[ConnectivityResult.none]);
    await pumpEventQueue();
    expect(sent, isEmpty);

    online = true;
    changes.add(<ConnectivityResult>[ConnectivityResult.wifi]);
    await pumpEventQueue();

    expect(sent.single.payload['e'], 1);
    expect(s.pending, 0);
    await s.stop();
    await changes.close();
  });

  test('TelemetrySdkDependencies-style enableSpool installs the transport',
      () async {
    final s = spool();
    TelemetryBootstrap.enableSpool(spool: s);
    online = false;
    await TelemetryClient.I.logError(type: 'boom');
    expect(s.pending, 1);
    await s.stop();
  });
}
