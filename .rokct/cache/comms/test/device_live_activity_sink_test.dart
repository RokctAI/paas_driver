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
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

LiveActivitySnapshot _order({
  LiveActivityState state = LiveActivityState.live,
  double? progress = 0.62,
  bool approximate = false,
}) =>
    LiveActivitySnapshot(
      key: 'order:1',
      kind: LiveActivityKind.orderTracking,
      title: 'On the way',
      subtitle: 'Thabo, 2.1 km away',
      progress: progress,
      segments: const ['Placed', 'Preparing', 'Picked up', 'On the way', 'Arriving'],
      trackerIcon: LiveActivityTracker.car,
      endsAt: DateTime(2026, 9, 25, 12, 52),
      endsAtLabel: 'Arrives',
      endsAtApproximate: approximate,
      state: state,
    );

void main() {
  group('LiveActivityText', () {
    test('Android 15 title and body carry the end time and stage', () {
      expect(LiveActivityText.compactTitle(_order()), 'On the way · arrives 12:52');
      expect(LiveActivityText.compactBody(_order()),
          'Stage 4 of 5 · Thabo, 2.1 km away');
    });

    test('approximate end time says about; ending says Now', () {
      expect(LiveActivityText.endLabel(_order(approximate: true)),
          'Arrives about 12:52');
      expect(LiveActivityText.endLabel(_order(state: LiveActivityState.ending)),
          'Now');
      expect(LiveActivityText.endLabel(_order(state: LiveActivityState.ended)),
          '');
    });
  });

  group('androidDetails', () {
    test('silent live update: ongoing only when not dismissible', () {
      final d = DeviceLiveActivitySink.androidDetails(LiveActivityFrame(
        id: 7,
        snapshot: _order(),
        alert: false,
      ));
      expect(d.channelId, 'live_updates');
      expect(d.channelName, 'Live updates');
      expect(d.importance, Importance.defaultImportance);
      expect(d.onlyAlertOnce, isTrue);
      expect(d.silent, isTrue);
      expect(d.ongoing, isFalse);
      expect(d.showProgress, isTrue);
      expect(d.progress, 62);
      expect(d.timeoutAfter, isNull);
      expect(d.color, LiveActivityTokens.segmentDone);
    });

    test('driver entry cannot be swiped while live', () {
      final d = DeviceLiveActivitySink.androidDetails(LiveActivityFrame(
        id: 7,
        snapshot: _order().copyWith(dismissible: false),
        alert: false,
      ));
      expect(d.ongoing, isTrue);
    });

    test('ended alerts once, turns green, clears after 15 min', () {
      final d = DeviceLiveActivitySink.androidDetails(LiveActivityFrame(
        id: 7,
        snapshot: _order(state: LiveActivityState.ended, progress: 1)
            .copyWith(dismissible: false),
        alert: true,
      ));
      expect(d.onlyAlertOnce, isFalse);
      expect(d.silent, isFalse);
      expect(d.ongoing, isFalse);
      expect(d.color, LiveActivityTokens.ended);
      expect(d.timeoutAfter, const Duration(minutes: 15).inMilliseconds);
    });

    test('error is red and clears after 60 min', () {
      final d = DeviceLiveActivitySink.androidDetails(LiveActivityFrame(
        id: 7,
        snapshot: _order(state: LiveActivityState.error, progress: 0.4),
        alert: true,
      ));
      expect(d.color, LiveActivityTokens.error);
      expect(d.progress, 40);
      expect(d.timeoutAfter, const Duration(minutes: 60).inMilliseconds);
    });

    test('class countdown uses a counting-down chronometer', () {
      final start = DateTime(2026, 9, 25, 14);
      final d = DeviceLiveActivitySink.androidDetails(LiveActivityFrame(
        id: 9,
        snapshot: LiveActivitySnapshot(
          key: 'class:1',
          kind: LiveActivityKind.classCountdown,
          title: 'Maths starts in',
          progress: 0.68,
          endsAt: start,
          countdown: true,
        ),
        alert: false,
      ));
      expect(d.usesChronometer, isTrue);
      expect(d.chronometerCountDown, isTrue);
      expect(d.when, start.millisecondsSinceEpoch);
      expect(d.showWhen, isTrue);
    });
  });

  test('showProgress false draws no bar', () {
    final d = DeviceLiveActivitySink.androidDetails(LiveActivityFrame(
      id: 3,
      snapshot: LiveActivitySnapshot(
        key: 'driver:active',
        kind: LiveActivityKind.driverDelivery,
        title: 'Online · waiting for orders',
        showProgress: false,
        dismissible: false,
      ),
      alert: false,
    ));
    expect(d.showProgress, isFalse);
    expect(d.indeterminate, isFalse);
    expect(d.ongoing, isTrue);
  });
}
