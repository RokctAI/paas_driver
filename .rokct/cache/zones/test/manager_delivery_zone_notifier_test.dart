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

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:zones_sdk/src/common/domain/interface/delivery_zones.dart';
import 'package:zones_sdk/src/manager/application/delivery_zone/delivery_zone_notifier.dart';

/// In-memory facade: serves a fixed ring, records what save receives.
class _FakeZones implements DeliveryZonesFacade {
  _FakeZones(this.served);

  final List<List<double>> served;
  List<List<double>>? saved;
  bool failUpdate = false;

  @override
  Future<ApiResult<List<List<double>>>> fetchDeliveryZones() async =>
      ApiResult.success(data: served);

  @override
  Future<ApiResult<void>> updateDeliveryZones({
    required List<List<double>> points,
  }) async {
    if (failUpdate) {
      return const ApiResult.failure(error: 'nope', statusCode: 500);
    }
    saved = points;
    return const ApiResult.success(data: null);
  }
}

const _servedRing = [
  [-26.10, 28.00],
  [-26.10, 28.08],
  [-26.16, 28.08],
  [-26.16, 28.00],
];

void main() {
  group('fetchDeliveryZone', () {
    test('seeds the saved ring as the editable ring, undo stack empty',
        () async {
      final notifier = DeliveryZoneNotifier(_FakeZones(_servedRing));
      await notifier.fetchDeliveryZone();

      expect(notifier.state.tappedPoints, const [
        LatLng(-26.10, 28.00),
        LatLng(-26.10, 28.08),
        LatLng(-26.16, 28.08),
        LatLng(-26.16, 28.00),
      ]);
      expect(notifier.state.canUndo, isFalse);
      expect(notifier.state.isDirty, isFalse);
      expect(notifier.state.isShapeClosed, isTrue);
      expect(notifier.state.polygon, hasLength(1));
    });

    test('empty server ring leaves an empty, open editor', () async {
      final notifier = DeliveryZoneNotifier(_FakeZones(const []));
      await notifier.fetchDeliveryZone();

      expect(notifier.state.tappedPoints, isEmpty);
      expect(notifier.state.isShapeClosed, isFalse);
      expect(notifier.state.polygon, isEmpty);
    });
  });

  group('vertex edits and undo', () {
    test('taps EXTEND the fetched shape instead of starting over', () async {
      final notifier = DeliveryZoneNotifier(_FakeZones(_servedRing));
      await notifier.fetchDeliveryZone();

      notifier.addTappedPoint(const LatLng(-26.13, 27.97));

      expect(notifier.state.tappedPoints, hasLength(5));
      expect(notifier.state.tappedPoints.last, const LatLng(-26.13, 27.97));
      expect(notifier.state.isDirty, isTrue);
    });

    test('add and drag each push one undo step; undo unwinds in reverse',
        () async {
      final notifier = DeliveryZoneNotifier(_FakeZones(const []));
      await notifier.fetchDeliveryZone();

      notifier.addTappedPoint(const LatLng(0, 0));
      notifier.addTappedPoint(const LatLng(0, 1));
      notifier.moveTappedPoint(1, const LatLng(0, 2));
      expect(notifier.state.tappedPoints, const [LatLng(0, 0), LatLng(0, 2)]);
      expect(notifier.state.pointsHistory, hasLength(3));

      notifier.undoLastPoint(); // undo the drag
      expect(notifier.state.tappedPoints, const [LatLng(0, 0), LatLng(0, 1)]);

      notifier.undoLastPoint(); // undo the second tap
      expect(notifier.state.tappedPoints, const [LatLng(0, 0)]);

      notifier.undoLastPoint(); // undo the first tap
      expect(notifier.state.tappedPoints, isEmpty);
      expect(notifier.state.canUndo, isFalse);
      expect(notifier.state.isDirty, isFalse);

      // Nothing left to undo: a further undo is a no-op, not a throw.
      notifier.undoLastPoint();
      expect(notifier.state.tappedPoints, isEmpty);
    });

    test('undoing every edit restores the fetched ring and Saved state',
        () async {
      final notifier = DeliveryZoneNotifier(_FakeZones(_servedRing));
      await notifier.fetchDeliveryZone();
      final before = notifier.state.tappedPoints;

      notifier.addTappedPoint(const LatLng(-26.13, 27.97));
      notifier.moveTappedPoint(0, const LatLng(-26.09, 27.99));
      notifier.undoLastPoint();
      notifier.undoLastPoint();

      expect(notifier.state.tappedPoints, before);
      expect(notifier.state.isDirty, isFalse);
    });

    test('out-of-range drag indices are ignored', () async {
      final notifier = DeliveryZoneNotifier(_FakeZones(const []));
      await notifier.fetchDeliveryZone();
      notifier.addTappedPoint(const LatLng(0, 0));

      notifier.moveTappedPoint(-1, const LatLng(1, 1));
      notifier.moveTappedPoint(1, const LatLng(1, 1));

      expect(notifier.state.tappedPoints, const [LatLng(0, 0)]);
      expect(notifier.state.pointsHistory, hasLength(1));
    });

    test('polygon styling follows the Save gate: open below 4 vertices,'
        ' closed at 4', () async {
      final notifier = DeliveryZoneNotifier(_FakeZones(const []));
      await notifier.fetchDeliveryZone();

      notifier.addTappedPoint(const LatLng(0, 0));
      notifier.addTappedPoint(const LatLng(0, 1));
      notifier.addTappedPoint(const LatLng(1, 1));
      expect(notifier.state.isShapeClosed, isFalse);
      expect(notifier.state.polygon.first.strokeWidth, 0);

      notifier.addTappedPoint(const LatLng(1, 0));
      expect(notifier.state.isShapeClosed, isTrue);
      // The shipped closed styling: primary stroke, width 4.
      expect(notifier.state.polygon.first.strokeWidth, 4);
    });
  });

  group('updateDeliveryZone', () {
    test('sends the edited ring and clears the undo stack on success',
        () async {
      final zones = _FakeZones(_servedRing);
      final notifier = DeliveryZoneNotifier(zones);
      await notifier.fetchDeliveryZone();
      notifier.addTappedPoint(const LatLng(-26.13, 27.97));

      var popped = false;
      await notifier.updateDeliveryZone(updateSuccess: () => popped = true);

      expect(popped, isTrue);
      expect(zones.saved, hasLength(5));
      expect(zones.saved!.last, [-26.13, 27.97]);
      expect(notifier.state.isDirty, isFalse);
      expect(notifier.state.canUndo, isFalse);
      // The vertices themselves are untouched by the save.
      expect(notifier.state.tappedPoints, hasLength(5));
    });

    test('a failed save keeps the undo stack (still Drawing)', () async {
      final zones = _FakeZones(_servedRing)..failUpdate = true;
      final notifier = DeliveryZoneNotifier(zones);
      await notifier.fetchDeliveryZone();
      notifier.addTappedPoint(const LatLng(-26.13, 27.97));

      var popped = false;
      await notifier.updateDeliveryZone(updateSuccess: () => popped = true);

      expect(popped, isFalse);
      expect(zones.saved, isNull);
      expect(notifier.state.isDirty, isTrue);
      expect(notifier.state.canUndo, isTrue);
    });
  });
}
