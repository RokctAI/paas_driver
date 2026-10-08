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

import 'package:base_sdk/base_sdk.dart'
    show
        LiveActivities,
        LiveActivityFrame,
        LiveActivitySink,
        LiveActivityState,
        PushMessages;
import 'package:base_sdk/src/domain/interface/orders.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/models/data/local_location.dart';
import 'package:base_sdk/src/models/data/order_active_model.dart';
import 'package:base_sdk/src/models/data/shop_data.dart' show Location;
import 'package:comms_sdk/comms_sdk.dart'
    show DeviceLiveActivitySink, PushMessageDispatcher;
import 'package:firebase_messaging/firebase_messaging.dart' show RemoteMessage;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orders_sdk/src/common/application/live/active_order_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// End to end: an FCM `order_status` message goes through comms'
/// [PushMessageDispatcher] into base's [PushMessages], whose handler is
/// the [ActiveOrderTracker]; the tracker polls the (fake) repository and
/// publishes to the live-activity sink.

class _Sink implements LiveActivitySink {
  final List<LiveActivityFrame> frames = [];
  final List<int> cancelled = [];
  @override
  Future<void> show(LiveActivityFrame frame) async => frames.add(frame);
  @override
  Future<void> cancel(int id, String key) async => cancelled.add(id);
}

class _Repo implements OrdersRepositoryFacade {
  final Map<String, OrderActiveModel> orders = {};
  final List<String> reads = [];

  @override
  Future<ApiResult<OrderActiveModel>> getSingleOrder(String orderId) async {
    reads.add(orderId);
    final o = orders[orderId];
    return o == null
        ? const ApiResult.failure(error: 'gone', statusCode: 404)
        : ApiResult.success(data: o);
  }

  @override
  Future<ApiResult<LocalLocation>> getDriverLocation(String deliveryId) async =>
      ApiResult.success(
        data: LocalLocation(latitude: -33.93, longitude: 18.43),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAndroidNotifications extends AndroidFlutterLocalNotificationsPlugin {
  final List<(int, String?, AndroidNotificationDetails?)> shown = [];
  @override
  Future<bool> initialize(
    AndroidInitializationSettings initializationSettings, {
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async => true;
  @override
  Future<void> show(
    int id,
    String? title,
    String? body, {
    AndroidNotificationDetails? notificationDetails,
    String? payload,
  }) async => shown.add((id, title, notificationDetails));
}

OrderActiveModel _order(String id, String status) => OrderActiveModel(
  id: id,
  status: status,
  deliveryType: 'delivery',
  location: Location(latitude: -33.92, longitude: 18.42),
  deliveryMan: DeliveryMan(id: 'd1', firstname: 'Thabo', phone: '+27000'),
);

RemoteMessage _fcm(String orderId, String status) => RemoteMessage(
  messageId: 'm-$orderId-$status',
  data: <String, dynamic>{
    'type': ActiveOrderTracker.pushType,
    'order_id': orderId,
    'status': status,
  },
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Repo repo;
  late PushMessages push;
  late PushMessageDispatcher dispatcher;
  late LiveActivities activities;
  late ActiveOrderTracker tracker;

  void build(LiveActivitySink sink) {
    activities = LiveActivities(sink: sink, minInterval: Duration.zero);
    tracker = ActiveOrderTracker(
      repository: () => repo,
      fetchActive: () async => <OrderActiveModel>[],
      activities: activities,
      pushMessages: push,
      signedIn: () => true,
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = _Repo();
    push = PushMessages();
    dispatcher = PushMessageDispatcher(messages: push);
  });

  void tw(String name, Future<void> Function(WidgetTester) body) =>
      testWidgets(name, (tester) async {
        try {
          await body(tester);
        } finally {
          tracker.detach();
          activities.clearAll();
          debugDefaultTargetPlatformOverride = null;
        }
      });

  tw('foreground order_status push refreshes the tracker into the sink', (
    tester,
  ) async {
    final sink = _Sink();
    build(sink);
    tracker.attach();
    await tester.pump();
    expect(push.handles(ActiveOrderTracker.pushType), isTrue);
    expect(sink.frames, isEmpty);

    repo.orders['ORD-7'] = _order('ORD-7', 'Accepted');
    await dispatcher.dispatch(_fcm('ORD-7', 'accepted').data);
    expect(repo.reads, ['ORD-7']);
    expect(tracker.isTracking('ORD-7'), isTrue);
    expect(sink.frames, hasLength(1));
    expect(sink.frames.single.snapshot.key, 'order:ORD-7');
    expect(sink.frames.single.alert, isTrue);

    repo.orders['ORD-7'] = _order('ORD-7', 'Shipped');
    await dispatcher.dispatch(_fcm('ORD-7', 'on_a_way').data);
    expect(repo.reads, ['ORD-7', 'ORD-7']);
    expect(sink.frames.last.snapshot.title, 'On the way');
    expect(sink.frames.last.alert, isFalse);
    expect(tracker.intervalFor('ORD-7'), ActiveOrderTracker.onWayPoll);

    repo.orders['ORD-7'] = _order('ORD-7', 'Delivered');
    await dispatcher.dispatch(_fcm('ORD-7', 'delivered').data);
    expect(sink.frames.last.snapshot.state, LiveActivityState.ended);
    expect(tracker.isTracking('ORD-7'), isFalse);
  });

  tw('a message queued in the background is replayed into the tracker', (
    tester,
  ) async {
    final sink = _Sink();
    build(sink);
    tracker.attach();
    await tester.pump();

    repo.orders['ORD-8'] = _order('ORD-8', 'Ready');
    await PushMessageDispatcher.queueBackground(_fcm('ORD-8', 'ready').data);
    expect(repo.reads, isEmpty);
    await dispatcher.replayQueued();
    expect(repo.reads, ['ORD-8']);
    expect(sink.frames.single.snapshot.key, 'order:ORD-8');
    await dispatcher.replayQueued();
    expect(repo.reads, ['ORD-8'], reason: 'replayed once');
  });

  tw('messages of another type or without an order id do nothing', (
    tester,
  ) async {
    final sink = _Sink();
    build(sink);
    tracker.attach();
    await tester.pump();
    await dispatcher.dispatch(
      const RemoteMessage(
        data: <String, dynamic>{'type': 'chat', 'order_id': 'X'},
      ).data,
    );
    await dispatcher.dispatch(
      const RemoteMessage(data: <String, dynamic>{'type': 'order_status'}).data,
    );
    await dispatcher.dispatch(const RemoteMessage().data);
    expect(repo.reads, isEmpty);
    expect(sink.frames, isEmpty);
  });

  tw('through DeviceLiveActivitySink to flutter_local_notifications', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final fake = _FakeAndroidNotifications();
    FlutterLocalNotificationsPlatform.instance = fake;
    build(DeviceLiveActivitySink());
    tracker.attach();
    await tester.pump();

    repo.orders['ORD-9'] = _order('ORD-9', 'Shipped');
    await tester.runAsync(
      () => dispatcher.dispatch(_fcm('ORD-9', 'on_a_way').data),
    );
    expect(fake.shown, hasLength(1));
    final (id, title, details) = fake.shown.single;
    expect(id, LiveActivities.idFor('order:ORD-9'));
    expect(title, startsWith('On the way'));
    expect(details!.channelId, DeviceLiveActivitySink.androidChannelId);
    expect(details.silent, isFalse);
  });
}
