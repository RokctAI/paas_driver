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

// Gateway contract for the courier's own parcel tabs. The active and
// history reads used to GET the Laravel-era
// `/api/v1/dashboard/deliveryman/parcel-orders/paginate` path, which no
// Frappe router rule serves (a 404 behind every tab); they now travel the
// universal platform gateway under delivery's own
// `api.delivery_man.get_deliveryman_parcel_orders` alias. That def takes
// offset paging and nothing else, so these tests pin the cmd, the
// page-to-offset arithmetic, and the client-side status/date split that
// keeps the two tabs meaning what they meant.

import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/models/data/parcel_order.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/parcel_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/recording_http_service.dart';

/// What frappe.get_list hands back for the def's field list, newest first.
const _rows = [
  {
    'name': 'PO-ON-WAY',
    'status': 'On a way',
    'total_price': 120.0,
    'delivery_date': '2026-09-01',
  },
  {
    'name': 'PO-READY',
    'status': 'Ready',
    'total_price': 80.0,
    'delivery_date': '2026-09-02',
  },
  {
    'name': 'PO-DONE',
    'status': 'Delivered',
    'total_price': 50.5,
    'delivery_date': '2026-08-20',
  },
  {
    'name': 'PO-OLD',
    'status': 'Delivered',
    'total_price': 10.0,
    'delivery_date': '2026-07-01',
  },
  {
    'name': 'PO-NEW',
    'status': 'New',
    'total_price': 5.0,
    'delivery_date': null,
  },
];

/// The ids a tab would list, or a test failure; sealed-class pattern
/// matching so the test does not depend on which freezed generation emits
/// `when`.
List<String?> _ids(ApiResult<List<ParcelOrder>> result) => switch (result) {
      Success(:final data) => data.map((o) => o.id).toList(),
      Failure(:final error) => throw StateError('unexpected failure: $error'),
    };

void main() {
  tearDown(() async {
    await getIt.reset();
  });

  group('CourierParcelRepository.getActiveOrders', () {
    test('posts the delivery-owned cmd with offset paging', () async {
      final http = RecordingHttpService.install((_) => _rows);

      await CourierParcelRepository().getActiveOrders(2);

      final request = http.single;
      expect(request.method, 'POST');
      expect(request.path, kPlatformGatewayPath);
      expect(request.cmd, 'api.delivery_man.get_deliveryman_parcel_orders');
      expect(request.payload, {'limit_start': 50, 'limit_page_length': 50});
      expect(request.requireAuth, isTrue);
      expect(request.queryParameters, isEmpty,
          reason: 'the legacy GET query string must not survive the repoint');
    });

    test('page 1 starts at offset 0', () async {
      final http = RecordingHttpService.install((_) => const []);

      await CourierParcelRepository().getActiveOrders(1);

      expect(http.single.payload!['limit_start'], 0);
    });

    test('keeps the claimed-but-open statuses and mirrors docname as id',
        () async {
      RecordingHttpService.install((_) => _rows);

      final result = await CourierParcelRepository().getActiveOrders(1);

      expect(_ids(result), ['PO-ON-WAY', 'PO-READY']);
    });

    test('reports a transport failure instead of throwing', () async {
      RecordingHttpService.install((_) => throw StateError('boom'));

      final result = await CourierParcelRepository().getActiveOrders(1);

      expect(result, isA<Failure<List<ParcelOrder>>>());
    });
  });

  group('CourierParcelRepository.getHistoryOrders', () {
    test('uses the same cmd and keeps only delivered parcels', () async {
      final http = RecordingHttpService.install((_) => _rows);

      final result = await CourierParcelRepository().getHistoryOrders(1);

      expect(http.single.cmd, 'api.delivery_man.get_deliveryman_parcel_orders');
      expect(http.single.payload, {'limit_start': 0, 'limit_page_length': 50});
      expect(_ids(result), ['PO-DONE', 'PO-OLD']);
    });

    test('applies the delivery-date window inclusively on both bounds',
        () async {
      RecordingHttpService.install((_) => _rows);

      final result = await CourierParcelRepository().getHistoryOrders(
        1,
        start: DateTime(2026, 8, 1),
        end: DateTime(2026, 8, 20),
      );

      expect(_ids(result), ['PO-DONE']);
    });

    test('a lower bound alone works, like the legacy date_from', () async {
      RecordingHttpService.install((_) => _rows);

      final result = await CourierParcelRepository().getHistoryOrders(
        1,
        start: DateTime(2026, 8, 1),
      );

      expect(_ids(result), ['PO-DONE']);
    });
  });

  group('CourierParcelRepository.parseOwnParcels', () {
    test('accepts the {data: [...]} paginate envelope too', () {
      final orders = CourierParcelRepository.parseOwnParcels(
        {'data': _rows, 'meta': {'total': 5}},
        keep: const {'delivered'},
      );

      expect(orders.map((o) => o.id), ['PO-DONE', 'PO-OLD']);
      expect(orders.first.totalPrice, 50.5);
      expect(orders.first.deliveryDate, DateTime(2026, 8, 20));
    });

    test('legacy lowercase statuses and Select labels are the same status',
        () {
      final orders = CourierParcelRepository.parseOwnParcels(
        const [
          {'name': 'A', 'status': 'on_a_way'},
          {'name': 'B', 'status': 'On a way'},
          {'name': 'C', 'status': ' ACCEPTED '},
          {'name': 'D', 'status': 'Canceled'},
        ],
        keep: const {'accepted', 'ready', 'on_a_way'},
      );

      expect(orders.map((o) => o.id), ['A', 'B', 'C']);
    });

    test('an explicit id wins over the docname mirror', () {
      final orders = CourierParcelRepository.parseOwnParcels(
        const [
          {'id': 'explicit', 'name': 'docname', 'status': 'Delivered'},
        ],
        keep: const {'delivered'},
      );

      expect(orders.single.id, 'explicit');
    });

    test('a windowed read drops rows without a delivery date', () {
      final orders = CourierParcelRepository.parseOwnParcels(
        const [
          {'name': 'undated', 'status': 'Delivered'},
        ],
        keep: const {'delivered'},
        from: DateTime(2026, 1, 1),
      );

      expect(orders, isEmpty);
    });

    test('anything but a row list is an empty page', () {
      expect(
        CourierParcelRepository.parseOwnParcels(null, keep: const {'x'}),
        isEmpty,
      );
      expect(
        CourierParcelRepository.parseOwnParcels('nope', keep: const {'x'}),
        isEmpty,
      );
    });
  });
}
