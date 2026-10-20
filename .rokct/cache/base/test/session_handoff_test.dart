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

import 'package:base_sdk/src/services/session_handoff.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(SessionHandoff.channelName);
  final calls = <MethodCall>[];

  void answer(Object? Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return handler(call);
    });
  }

  setUp(() {
    calls.clear();
    SessionHandoff.resetForTesting();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('open is a no-op without a payload provider (no auth_sdk)', () async {
    answer((_) => true);
    expect(await SessionHandoff.open('com.example.manager'), isFalse);
    expect(calls, isEmpty);
  });

  test('open hands over the code and the account record', () async {
    answer((call) => true);
    SessionHandoff.payloadProvider = (pkg) async => const SessionHandoffPayload(
          code: 'one-time',
          account: {'v': 1, 'synced': true},
        );
    expect(await SessionHandoff.open('com.example.manager'), isTrue);
    expect(calls.map((c) => c.method),
        ['canHandOff', 'openWithHandoff']);
    final args = calls.last.arguments as Map;
    expect(args['package'], 'com.example.manager');
    expect(args['code'], 'one-time');
    expect(jsonDecode(args['account'] as String), {'v': 1, 'synced': true});
  });

  test('a package that is not a same-key fleet app is never asked for a code',
      () async {
    answer((call) => call.method == 'canHandOff' ? false : true);
    var asked = false;
    SessionHandoff.payloadProvider = (pkg) async {
      asked = true;
      return const SessionHandoffPayload(code: 'x');
    };
    expect(await SessionHandoff.open('com.other.app'), isFalse);
    expect(asked, isFalse);
  });

  test('nothing to hand over opens the ordinary way', () async {
    answer((_) => true);
    SessionHandoff.payloadProvider = (pkg) async => null;
    expect(await SessionHandoff.open('com.example.manager'), isFalse);
    expect(calls.map((c) => c.method), ['canHandOff']);
  });

  test('a missing native channel reads as false, never throws', () async {
    SessionHandoff.payloadProvider =
        (pkg) async => const SessionHandoffPayload(code: 'x');
    expect(await SessionHandoff.open('com.example.manager'), isFalse);
    expect(await SessionHandoff.takePending(), isNull);
  });

  test('not Android: no channel calls at all', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    answer((_) => true);
    SessionHandoff.payloadProvider =
        (pkg) async => const SessionHandoffPayload(code: 'x');
    expect(await SessionHandoff.open('com.example.manager'), isFalse);
    expect(await SessionHandoff.takePending(), isNull);
    expect(calls, isEmpty);
  });

  test('takePending parses the code, account and source', () async {
    answer((call) => {
          'code': 'c1',
          'account': jsonEncode({'local_id': '42', 'synced': false}),
          'source': 'com.example.launcher',
        });
    final payload = await SessionHandoff.takePending();
    expect(payload, isNotNull);
    expect(payload!.code, 'c1');
    expect(payload.account, {'local_id': '42', 'synced': false});
    expect(payload.sourcePackage, 'com.example.launcher');
  });

  test('parse drops garbage', () {
    expect(SessionHandoff.parse(null), isNull);
    expect(SessionHandoff.parse({}), isNull);
    expect(SessionHandoff.parse({'account': 'not json'}), isNull);
    expect(SessionHandoff.parse({'code': ''}), isNull);
  });

  test('toString never prints the code', () {
    const payload = SessionHandoffPayload(code: 'secret-code');
    expect(payload.toString(), isNot(contains('secret-code')));
  });
}
