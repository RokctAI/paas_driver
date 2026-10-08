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

import 'dart:async';

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
import 'package:base_sdk/src/models/response/order_paginate_response.dart';
import 'package:base_sdk/src/models/data/shop_data.dart' show Location;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orders_sdk/src/common/application/live/active_order_tracker.dart';

class _Sink implements LiveActivitySink {
  final List<LiveActivityFrame> frames = [];
  @override
  Future<void> show(LiveActivityFrame frame) async => frames.add(frame);
  @override
  Future<void> cancel(int id, String key) async {}
}

/// Serves orders by id; counts every read.
class _Repo implements OrdersRepositoryFacade {
  final Map<String, OrderActiveModel> orders = {};
  final List<String> reads = [];
  final List<String> driverReads = [];
  int listReads = 0;

  @override
  Future<ApiResult<OrderActiveModel>> getSingleOrder(String orderId) async {
    reads.add(orderId);
    final o = orders[orderId];
    return o == null
        ? const ApiResult.failure(error: 'gone', statusCode: 404)
        : ApiResult.success(data: o);
  }

  @override
  Future<ApiResult<LocalLocation>> getDriverLocation(String deliveryId) async {
    driverReads.add(deliveryId);
    return ApiResult.success(
        data: LocalLocation(latitude: -33.93, longitude: 18.43));
  }

  @override
  Future<ApiResult<OrderPaginateResponse>> getActiveOrders(int page) async {
    listReads++;
    return ApiResult.success(
        data: OrderPaginateResponse(data: orders.values.toList()));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

OrderActiveModel _order(String id, String status, {String type = 'delivery'}) =>
    OrderActiveModel(
      id: id,
      status: status,
      deliveryType: type,
      location: Location(latitude: -33.92, longitude: 18.42),
      deliveryMan: DeliveryMan(id: 'd1', firstname: 'Thabo', phone: '+27000'),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Repo repo;
  late _Sink sink;
  late PushMessages push;
  late ActiveOrderTracker tracker;
  late LiveActivities activities;
  var signedIn = true;

  ActiveOrderTracker make() => ActiveOrderTracker(
        repository: () => repo,
        activities: activities,
        pushMessages: push,
        signedIn: () => signedIn,
      );

  setUp(() {
    repo = _Repo();
    sink = _Sink();
    push = PushMessages();
    signedIn = true;
    activities = LiveActivities(sink: sink, minInterval: Duration.zero);
    tracker = make();
  });

  /// A widget test with the tracker's and the entries' timers cleared
  /// before the binding checks for pending timers.
  void tw(String name, Future<void> Function(WidgetTester) body) =>
      testWidgets(name, (tester) async {
        await body(tester);
        tracker.detach();
        activities.clearAll();
      });

  tw('attach lists active orders and starts their entries',
      (tester) async {
    repo.orders['A'] = _order('A', 'Accepted');
    repo.orders['B'] = _order('B', 'Ready');
    tracker.attach();
    await tester.pump();
    expect(repo.listReads, 1);
    expect(tracker.trackedIds, {'A', 'B'});
    expect(sink.frames.map((f) => f.snapshot.key).toSet(),
        {'order:A', 'order:B'});
    expect(tracker.intervalFor('A'), ActiveOrderTracker.idlePoll);
  });

  tw('15s on the way with the driver, 120s otherwise',
      (tester) async {
    repo.orders['A'] = _order('A', 'Accepted');
    tracker.track('A');
    await tester.pump();
    expect(tracker.intervalFor('A'), ActiveOrderTracker.idlePoll);
    expect(repo.driverReads, isEmpty);

    repo.orders['A'] = _order('A', 'Shipped'); // the doctype's on_a_way
    await tester.pump(ActiveOrderTracker.idlePoll);
    expect(repo.reads, ['A', 'A']);
    expect(tracker.intervalFor('A'), ActiveOrderTracker.onWayPoll);
    expect(repo.driverReads, ['d1']);
    expect(sink.frames.last.snapshot.title, 'On the way');

    await tester.pump(ActiveOrderTracker.onWayPoll);
    expect(repo.reads.length, 3);
  });

  tw('never polls in the background; resume syncs', (tester) async {
    repo.orders['A'] = _order('A', 'Accepted');
    tracker.track('A');
    await tester.pump();
    tracker.setForeground(false);
    expect(tracker.intervalFor('A'), isNull);
    await tester.pump(const Duration(minutes: 10));
    expect(repo.reads, ['A']);
    await tracker.onPush({'type': 'order_status', 'order_id': 'A'});
    expect(repo.reads, ['A'], reason: 'a push in the background waits');

    tracker.setForeground(true);
    await tester.pump();
    expect(repo.reads, ['A', 'A']);
    expect(tracker.intervalFor('A'), ActiveOrderTracker.idlePoll);
  });

  tw('stops at a terminal status after the final snapshot',
      (tester) async {
    repo.orders['A'] = _order('A', 'Shipped');
    tracker.track('A');
    await tester.pump();
    repo.orders['A'] = _order('A', 'Delivered');
    await tester.pump(ActiveOrderTracker.onWayPoll);
    expect(tracker.isTracking('A'), isFalse);
    expect(sink.frames.last.snapshot.state, LiveActivityState.ended);
    await tester.pump(const Duration(minutes: 5));
    expect(repo.reads.length, 2);
  });

  tw('cancelled (doctype spelling) ends in the error state',
      (tester) async {
    repo.orders['A'] = _order('A', 'Cancelled');
    tracker.track('A');
    await tester.pump();
    expect(tracker.isTracking('A'), isFalse);
    expect(sink.frames.single.snapshot.state, LiveActivityState.error);
  });

  tw('pickup orders get no entry and stop unless pinned',
      (tester) async {
    repo.orders['P'] = _order('P', 'Accepted', type: 'Pickup');
    tracker.track('P');
    await tester.pump();
    expect(sink.frames, isEmpty);
    expect(tracker.isTracking('P'), isFalse);

    tracker.track('P', pin: true); // the progress screen
    await tester.pump();
    expect(tracker.isTracking('P'), isTrue);
    expect(sink.frames, isEmpty);
    tracker.release('P');
    expect(tracker.isTracking('P'), isFalse);
  });

  tw('an order_status push starts and refreshes the order',
      (tester) async {
    repo.orders['N'] = _order('N', 'New');
    tracker.attach();
    await tester.pump();
    final before = repo.reads.length;
    repo.orders['N'] = _order('N', 'Accepted');
    expect(await push.dispatch(
        {'type': 'order_status', 'order_id': 'N', 'status': 'accepted'}),
        isTrue);
    await tester.pump();
    expect(repo.reads.length, before + 1);
    expect(sink.frames.last.snapshot.title, 'Preparing your order');
  });

  tw('updates stream carries the wire status for the screen',
      (tester) async {
    repo.orders['A'] = _order('A', 'Shipped');
    final seen = <String?>[];
    final sub = tracker.updates.listen((o) => seen.add(o.status));
    tracker.track('A');
    await tester.pump();
    expect(seen, ['on_a_way']);
    // Not awaited: under the fake clock the cancel future never completes.
    unawaited(sub.cancel());
  });

  tw('signed out: no list, and tracked orders stop',
      (tester) async {
    repo.orders['A'] = _order('A', 'Accepted');
    tracker.track('A');
    await tester.pump();
    signedIn = false;
    await tester.pump(ActiveOrderTracker.idlePoll);
    expect(tracker.isTracking('A'), isFalse);
    await tracker.sync();
    expect(repo.listReads, 0);
  });

  test('wireStatus maps the doctype options', () {
    expect(ActiveOrderTracker.wireStatus('Shipped'), 'on_a_way');
    expect(ActiveOrderTracker.wireStatus('Cooking'), 'accepted');
    expect(ActiveOrderTracker.wireStatus('Cancelled'), 'canceled');
    expect(ActiveOrderTracker.wireStatus('Paid'), 'delivered');
    expect(ActiveOrderTracker.wireStatus('Failed'), 'canceled');
    expect(ActiveOrderTracker.wireStatus('New'), 'new');
  });

  test('lifecycle: only resumed counts as foreground', () {
    final t = make();
    t.didChangeAppLifecycleState(AppLifecycleState.inactive);
    expect(t.foreground, isFalse);
    t.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(t.foreground, isFalse);
    t.detach();
  });
}
