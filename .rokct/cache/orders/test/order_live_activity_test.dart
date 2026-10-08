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
    show LiveActivities, LiveActivityState, LiveActivityTracker;
import 'package:base_sdk/src/models/data/order_active_model.dart';
import 'package:base_sdk/src/models/data/shop_data.dart';
import 'package:base_sdk/src/models/data/translation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orders_sdk/src/common/application/live/order_live_activity.dart';

OrderActiveModel _order(String status, {String? type = 'delivery'}) =>
    OrderActiveModel(
      id: '123',
      status: status,
      deliveryType: type,
      location: Location(latitude: -33.92, longitude: 18.42),
      deliveryDate: DateTime(2026, 9, 25),
      deliveryTime: '12:55',
      deliveryMan: DeliveryMan(id: 'd1', firstname: 'Thabo', phone: '+27000'),
      shop: ShopData(translation: Translation(title: "Nando's")),
      updatedAt: DateTime(2026, 9, 25, 12, 51),
    );

void main() {
  late OrderLiveActivity live;
  setUp(() => live = OrderLiveActivity(LiveActivities()));

  test('placed: stage 1, car, about the checkout time', () {
    final s = live.snapshotFor(_order('new'), appName: 'Marketplace')!;
    expect(s.key, 'order:123');
    expect(s.title, 'Order placed');
    expect(s.subtitle, "Waiting for Nando's to accept");
    expect(s.stageLabel, 'Stage 1 of 5');
    expect(s.trackerIcon, LiveActivityTracker.car);
    expect(s.endsAt, DateTime(2026, 9, 25, 12, 55));
    expect(s.endsAtApproximate, isTrue);
    expect(s.actions.map((a) => a.label), ['Track order']);
  });

  test('preparing: stage 2', () {
    final s = live.snapshotFor(_order('accepted'), appName: '')!;
    expect(s.title, 'Preparing your order');
    expect(s.stageLabel, 'Stage 2 of 5');
  });

  test('on the way without a location: Picked up, car does not guess', () {
    final s = live.snapshotFor(_order('on_a_way'), appName: '')!;
    expect(s.title, 'Picked up');
    expect(s.stageLabel, 'Stage 3 of 5');
    expect(s.actions.map((a) => a.label), ['Track order', 'Call driver']);
  });

  test('on the way: car moves with the distance left', () {
    final o = _order('on_a_way');
    final first = live.snapshotFor(o,
        driverLatitude: -33.94, driverLongitude: 18.42, appName: '')!;
    expect(first.title, 'On the way');
    expect(first.progress, closeTo(0.6, 1e-9));
    expect(first.subtitle, startsWith('Thabo · '));
    final closer = live.snapshotFor(o,
        driverLatitude: -33.93, driverLongitude: 18.42, appName: '')!;
    expect(closer.progress, greaterThan(0.6));
    expect(closer.stageLabel, 'Stage 4 of 5');
    // Location lost again: keeps the last position.
    final lost = live.snapshotFor(o, appName: '')!;
    expect(lost.progress, closer.progress);
  });

  test('arriving: ending state within 200 m', () {
    final s = live.snapshotFor(_order('on_a_way'),
        driverLatitude: -33.9205, driverLongitude: 18.42, appName: '')!;
    expect(s.title, 'Arriving now');
    expect(s.state, LiveActivityState.ending);
  });

  test('delivered and cancelled are terminal', () {
    final d = live.snapshotFor(_order('delivered'), appName: '')!;
    expect(d.title, 'Delivered 12:51');
    expect(d.state, LiveActivityState.ended);
    expect(d.actions.single.label, 'Rate order');
    final c = live.snapshotFor(_order('canceled'), appName: '')!;
    expect(c.title, 'Order cancelled');
    expect(c.state, LiveActivityState.error);
    expect(c.actions.single.label, 'Get help');
  });

  test('pickup orders get no live activity', () {
    expect(live.snapshotFor(_order('new', type: 'pickup'), appName: ''), isNull);
  });

  test('checkout time range uses its first clock time', () {
    final o = _order('new')..deliveryTime = '13:00 - 13:30';
    expect(OrderLiveActivity.chosenDeliveryTime(o), DateTime(2026, 9, 25, 13));
  });
}
