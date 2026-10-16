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

// Incoming Push Kit messages used to go nowhere: the token was registered
// but nothing listened for messages. They now raise a local notification
// and, in the foreground, reach base_sdk's PushMessages like FCM messages.

import 'dart:async';

import 'package:base_sdk/base_sdk.dart' show PushMessages;
import 'package:flutter_test/flutter_test.dart';
import 'package:huawei_push/huawei_push.dart';

import 'package:hms_sdk/src/services/hms_push_bootstrap.dart';
import 'package:hms_sdk/src/services/hms_push_messages.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Map<String, dynamic>> shown;
  late List<Map<String, dynamic>> dispatched;
  late PushMessages messages;
  late HmsPushMessages handler;

  setUp(() {
    shown = <Map<String, dynamic>>[];
    dispatched = <Map<String, dynamic>>[];
    messages = PushMessages()
      ..register('order_status', (data) => dispatched.add(data));
    handler = HmsPushMessages(
      notify: (attrs) async => shown.add(attrs),
      messages: messages,
    );
  });

  test('a data message with title and body raises a local notification',
      () async {
    final bool result = await handler.handle(
      data: <String, dynamic>{
        'type': 'order_status',
        'title': 'Order 42',
        'body': 'On its way',
      },
      messageId: 'm-1',
    );

    expect(result, isTrue);
    expect(shown, hasLength(1));
    final Map<String, dynamic> n = shown.single;
    expect(n[HMSLocalNotificationAttr.TITLE], 'Order 42');
    expect(n[HMSLocalNotificationAttr.MESSAGE], 'On its way');
    expect(n[HMSLocalNotificationAttr.CHANNEL_ID], 'general_notifications');
    expect(n[HMSLocalNotificationAttr.ID], '${'m-1'.hashCode & 0x7fffffff}');
    expect(
      n[HMSLocalNotificationAttr.DATA],
      <String, String>{
        'type': 'order_status',
        'title': 'Order 42',
        'body': 'On its way',
      },
    );
    // Foreground: the feature SDK handler ran too, as for FCM.
    expect(dispatched.single['type'], 'order_status');
  });

  test('the notification part wins over data keys', () async {
    await handler.handle(
      data: <String, dynamic>{'title': 'data title', 'message': 'data body'},
      title: 'Notice',
      body: 'Body',
    );
    expect(shown.single[HMSLocalNotificationAttr.TITLE], 'Notice');
    expect(shown.single[HMSLocalNotificationAttr.MESSAGE], 'Body');
  });

  test('`message` is accepted as the body key', () async {
    await handler.handle(data: <String, dynamic>{'message': 'Hello'});
    expect(shown.single[HMSLocalNotificationAttr.MESSAGE], 'Hello');
    expect(shown.single[HMSLocalNotificationAttr.TITLE], '');
  });

  test('a silent data message shows nothing but is still dispatched',
      () async {
    final bool result = await handler.handle(
      data: <String, dynamic>{'type': 'order_status', 'id': '7'},
    );
    expect(result, isFalse);
    expect(shown, isEmpty);
    expect(dispatched.single['id'], '7');
  });

  test('background messages notify without dispatching', () async {
    await handler.handle(
      data: <String, dynamic>{'type': 'order_status', 'title': 'T'},
      foreground: false,
    );
    expect(shown, hasLength(1));
    expect(dispatched, isEmpty);
  });

  test('a failing notifier is swallowed and dispatch still runs', () async {
    final failing = HmsPushMessages(
      notify: (_) async => throw StateError('no plugin'),
      messages: messages,
    );
    final bool result = await failing.handle(
      data: <String, dynamic>{'type': 'order_status', 'title': 'T'},
    );
    expect(result, isFalse);
    expect(dispatched, hasLength(1));
  });

  group('HmsPushBootstrap.listenForMessages', () {
    tearDown(() => HmsPushBootstrap.instance.reset());

    test('registers the background handler and listens for messages',
        () async {
      final controller = StreamController<RemoteMessage>.broadcast();
      final List<Object> registered = <Object>[];
      HmsPushBootstrap.instance.listenForMessages(
        messages: controller.stream,
        handler: handler,
        registerBackground: (cb) async {
          registered.add(cb);
          return true;
        },
      );
      await Future<void>.delayed(Duration.zero);
      expect(registered.single, same(hmsBackgroundMessageHandler));
      expect(controller.hasListener, isTrue);

      await HmsPushBootstrap.instance.reset();
      expect(controller.hasListener, isFalse);
      await controller.close();
    });

    test('a failing background registration is swallowed', () async {
      HmsPushBootstrap.instance.listenForMessages(
        messages: const Stream<RemoteMessage>.empty(),
        handler: handler,
        registerBackground: (_) async => throw StateError('no channel'),
      );
      await Future<void>.delayed(Duration.zero);
    });
  });
}
