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

import 'package:base_sdk/base_sdk.dart';
import 'package:comms_sdk/src/common/services/device_live_activity_sink.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records what flutter_local_notifications would hand the Android side.
class _FakeAndroidNotifications extends AndroidFlutterLocalNotificationsPlugin {
  int initialized = 0;
  final List<_Shown> shown = <_Shown>[];
  final List<int> cancelled = <int>[];

  @override
  Future<bool> initialize(
    AndroidInitializationSettings initializationSettings, {
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    initialized++;
    return true;
  }

  @override
  Future<void> show(
    int id,
    String? title,
    String? body, {
    AndroidNotificationDetails? notificationDetails,
    String? payload,
  }) async {
    shown.add(_Shown(id, title, body, notificationDetails, payload));
  }

  @override
  Future<void> cancel(int id, {String? tag}) async => cancelled.add(id);
}

class _Shown {
  _Shown(this.id, this.title, this.body, this.details, this.payload);
  final int id;
  final String? title;
  final String? body;
  final AndroidNotificationDetails? details;
  final String? payload;
}

LiveActivitySnapshot _order({
  String title = 'Preparing',
  String subtitle = 'Kitchen has your order',
  double? progress = 0.4,
  LiveActivityState state = LiveActivityState.live,
}) => LiveActivitySnapshot(
  key: 'order:ORD-1',
  kind: LiveActivityKind.orderTracking,
  title: title,
  subtitle: subtitle,
  progress: progress,
  segments: const [
    'Placed',
    'Preparing',
    'Picked up',
    'On the way',
    'Arriving',
  ],
  trackerIcon: LiveActivityTracker.car,
  deepLink: 'app://orders/ORD-1',
  appName: 'Marketplace',
  state: state,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAndroidNotifications fake;
  late LiveActivities live;
  final id = LiveActivities.idFor('order:ORD-1');

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    fake = _FakeAndroidNotifications();
    FlutterLocalNotificationsPlatform.instance = fake;
    // No host `rokct/live_updates` handler: MissingPluginException, so the
    // sink falls back to flutter_local_notifications (Android 15 path).
    live = LiveActivities(
      sink: DeviceLiveActivitySink(),
      minInterval: Duration.zero,
    );
  });

  tearDown(() {
    live.clearAll();
    debugDefaultTargetPlatformOverride = null;
  });

  test('order live notification: show, update in place, end, cancel', () async {
    await live.update(_order());
    expect(fake.initialized, lessThanOrEqualTo(1));
    expect(fake.shown, hasLength(1));
    final first = fake.shown.single;
    expect(first.id, id);
    expect(first.title, 'Preparing');
    expect(first.body, 'Stage 3 of 5 · Kitchen has your order');
    expect(first.payload, 'app://orders/ORD-1');
    final d1 = first.details!;
    expect(d1.channelId, DeviceLiveActivitySink.androidChannelId);
    expect(d1.channelName, DeviceLiveActivitySink.androidChannelName);
    expect(d1.category, AndroidNotificationCategory.progress);
    expect(d1.silent, isFalse, reason: 'first post alerts');
    expect(d1.onlyAlertOnce, isFalse);
    expect(d1.showProgress, isTrue);
    expect(d1.progress, 40);
    expect(d1.maxProgress, 100);
    expect(d1.subText, 'Marketplace');
    expect(d1.timeoutAfter, isNull);
    expect(d1.color, LiveActivityTokens.segmentDone);

    // Same snapshot again: nothing re-posted.
    await live.update(_order());
    expect(fake.shown, hasLength(1));

    // A new stage updates the same notification id silently.
    await live.update(
      _order(
        title: 'On the way',
        subtitle: 'Thabo, 2.1 km away',
        progress: 0.7,
      ),
    );
    expect(fake.shown, hasLength(2));
    final second = fake.shown.last;
    expect(second.id, id);
    expect(second.title, 'On the way');
    expect(second.body, 'Stage 4 of 5 · Thabo, 2.1 km away');
    expect(second.details!.silent, isTrue);
    expect(second.details!.onlyAlertOnce, isTrue);
    expect(second.details!.progress, 70);

    // Delivered: terminal, alerts once, clears itself after a timeout.
    await live.update(
      _order(
        title: 'Delivered',
        subtitle: 'Enjoy',
        progress: 1,
        state: LiveActivityState.ended,
      ),
    );
    expect(fake.shown, hasLength(3));
    final last = fake.shown.last;
    expect(last.id, id);
    expect(last.details!.silent, isFalse);
    expect(last.details!.timeoutAfter, isNotNull);
    expect(last.details!.ongoing, isFalse);
    expect(last.details!.color, LiveActivityTokens.ended);
    expect(live.isActive('order:ORD-1'), isFalse);

    // Updates after the end are dropped.
    await live.update(_order());
    expect(fake.shown, hasLength(3));

    await live.end('order:ORD-1');
    expect(fake.cancelled, [id]);
  });

  test('cancelled order shows the error colour', () async {
    await live.update(_order());
    await live.update(
      _order(title: 'Cancelled', subtitle: '', state: LiveActivityState.error),
    );
    final d = fake.shown.last.details!;
    expect(d.color, LiveActivityTokens.error);
    expect(d.timeoutAfter, isNotNull);
  });

  test('ending an order before it showed still cancels by id', () async {
    await live.end('order:ORD-1');
    expect(fake.shown, isEmpty);
    expect(fake.cancelled, [id]);
  });
}
