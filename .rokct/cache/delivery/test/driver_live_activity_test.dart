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
    show LiveActivities, LiveActivityFrame, LiveActivitySink, LiveActivityTracker;
import 'package:delivery_sdk/src/driver/infrastructure/models/data/push_data.dart';
import 'package:delivery_sdk/src/driver/application/home/home_state.dart';
import 'package:delivery_sdk/src/driver/application/live/driver_live_activity.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/order_detail.dart';
import 'package:flutter_test/flutter_test.dart';

class _Sink implements LiveActivitySink {
  final frames = <LiveActivityFrame>[];
  final cancelled = <String>[];
  @override
  Future<void> show(LiveActivityFrame frame) async => frames.add(frame);
  @override
  Future<void> cancel(int id, String key) async => cancelled.add(key);
}

OrderDetailData _order() => OrderDetailData(
      id: '4821',
      address: AddressModel(address: '14 Kloof St'),
      totalPrice: 185,
      currency: Currency(symbol: 'R'),
      deliveryDate: '2026-09-25',
      deliveryTime: '12:52',
      transaction: Transaction(paymentSystem: PaymentSystem(tag: 'cash')),
    );

void main() {
  test('offline: no entry', () {
    expect(DriverLiveActivity.snapshotFor(const HomeState(), online: false),
        isNull);
  });

  test('online, no delivery: ongoing, no bar', () {
    final s =
        DriverLiveActivity.snapshotFor(const HomeState(), online: true)!;
    expect(s.title, 'Online · waiting for orders');
    expect(s.showProgress, isFalse);
    expect(s.dismissible, isFalse);
  });

  test('go to customer: three segments, cash in the subtitle, Due time', () {
    final s = DriverLiveActivity.snapshotFor(
      HomeState(orderDetail: _order(), isGoUser: true),
      online: true,
    )!;
    expect(s.key, DriverLiveActivity.key);
    expect(s.title, 'Go to customer · order #4821');
    expect(s.subtitle, '14 Kloof St · cash R 185.00');
    expect(s.segments, hasLength(3));
    expect(s.stageLabel, 'Stage 3 of 3');
    expect(s.trackerIcon, LiveActivityTracker.scooter);
    expect(s.endsAt, DateTime(2026, 9, 25, 12, 52));
    expect(s.endsAtLabel, 'Due');
    expect(s.countdown, isFalse);
    expect(s.dismissible, isFalse);
    expect(s.actions.map((a) => a.label), ['Navigate', 'Delivered']);
    expect(s.actions.last.deepLink, contains('step=proof'));
  });

  test('go to restaurant: stage 1, no Delivered action', () {
    final s = DriverLiveActivity.snapshotFor(
      HomeState(orderDetail: _order(), isGoRestaurant: true),
      online: true,
    )!;
    expect(s.stageLabel, 'Stage 1 of 3');
    expect(s.actions.map((a) => a.label), ['Navigate']);
  });

  test('one key for the shift: delivery then waiting reuse the same id',
      () async {
    final sink = _Sink();
    final live = DriverLiveActivity(
        LiveActivities(sink: sink, minInterval: Duration.zero));
    await live.publish(HomeState(orderDetail: _order(), isGoUser: true),
        online: true);
    await live.publish(const HomeState(), online: true);
    expect(sink.frames.map((f) => f.id).toSet(), hasLength(1));
    await live.publish(const HomeState(), online: false);
    expect(sink.cancelled, [DriverLiveActivity.key]);
    // Back online: starts again under the same key.
    await live.publish(const HomeState(), online: true);
    expect(sink.frames.last.first, isTrue);
  });
}
