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

// Gateway contract for the customer-side delivery-point reads. The nearest
// points call used to GET a dotted `/api/method/paas.doctype...` path that
// no manifest registers (a silent 404 behind a spinner); it now travels the
// universal platform gateway under delivery's own
// `api.delivery.get_nearest_delivery_points` alias. These tests pin the
// cmd, the payload keys and the guest client so a later edit cannot drift
// back onto a dead path without failing here.

import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:delivery_sdk/src/common/infrastructure/repositories/delivery_points_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/recording_http_service.dart';

/// Unwraps a success or fails the test; sealed-class pattern matching so the
/// test does not depend on which freezed generation emits `when`.
T _data<T>(ApiResult<T> result) => switch (result) {
      Success(:final data) => data,
      Failure(:final error) => throw StateError('unexpected failure: $error'),
    };

const _point = {
  'name': 'DP-0001',
  'address': '1 Test Street',
  'latitude': -26.2041,
  'longitude': 28.0473,
  'img': null,
  'distance': 0.42,
};

void main() {
  tearDown(() async {
    await getIt.reset();
  });

  group('DeliveryPointsRepository.getDeliveryPoints', () {
    test('posts the delivery-owned cmd with the coordinates as payload',
        () async {
      final http = RecordingHttpService.install((_) => [_point]);

      final result = await DeliveryPointsRepository().getDeliveryPoints(
        latitude: -26.2041,
        longitude: 28.0473,
      );

      final request = http.single;
      expect(request.method, 'POST');
      expect(request.path, kPlatformGatewayPath);
      expect(request.cmd, 'api.delivery.get_nearest_delivery_points');
      expect(request.payload, {'latitude': -26.2041, 'longitude': 28.0473});
      expect(request.queryParameters, isEmpty,
          reason: 'the legacy GET query string must not survive the repoint');

      final points = _data(result);
      expect(points.single.id, 'DP-0001');
      expect(points.single.address, '1 Test Street');
      expect(points.single.distance, 0.42);
    });

    test('stays a guest call - the def is allow_guest like its siblings',
        () async {
      final http = RecordingHttpService.install((_) => const []);

      await DeliveryPointsRepository().getDeliveryPoints(
        latitude: 0,
        longitude: 0,
      );

      expect(http.single.requireAuth, isFalse);
    });

    test('reports a transport failure instead of throwing', () async {
      RecordingHttpService.install((_) => throw StateError('boom'));

      final result = await DeliveryPointsRepository().getDeliveryPoints(
        latitude: 0,
        longitude: 0,
      );

      expect(result, isA<Failure<dynamic>>());
    });
  });

  group('DeliveryPointsRepository.getAllDeliveryPoints', () {
    test('keeps its existing guest gateway cmd', () async {
      final http = RecordingHttpService.install((_) => [_point]);

      final result = await DeliveryPointsRepository().getAllDeliveryPoints();

      final request = http.single;
      expect(request.path, kPlatformGatewayPath);
      expect(request.cmd, 'api.delivery.get_delivery_points');
      expect(request.payload, isNull);
      expect(request.requireAuth, isFalse);
      expect(_data(result), hasLength(1));
    });
  });
}
