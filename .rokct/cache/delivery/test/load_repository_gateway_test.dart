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

// Gateway contract for the driver's van-sales calls. They travel the
// universal platform gateway under commerce's own `api.order.load.*`
// aliases. These tests pin the cmds, the payload keys and the envelope the
// answers are read out of — the four things a backend rename would break
// silently.

import 'dart:convert';

import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:delivery_sdk/src/driver/domain/interface/load.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/load_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/recording_http_service.dart';

T _data<T>(ApiResult<T> result) => switch (result) {
      Success(:final data) => data,
      Failure(:final error) => throw StateError('unexpected failure: $error'),
    };

Map<String, dynamic> _loadRow() => {
      'id': 'LOAD-4',
      'shop': {'id': 'SHOP-1', 'title': 'Depot North'},
      'load_status': 'Open',
      'lines': [
        {
          'item_id': 'LI-1',
          'stock_id': 'STK-1',
          'unit_price': 45,
          'issued_qty': 10,
          'sold_qty': 3,
          'returned_qty': 1,
          'remaining_qty': 6,
          'product': {
            'uuid': 'PRD-WATER-5L',
            'translation': {'title': 'Still water 5L'},
            'unit': {'translation': {'title': 'bottle'}},
          },
        },
      ],
    };

/// The `items` argument as it leaves the client.
List<dynamic> _items(Map<String, dynamic>? payload) =>
    jsonDecode(payload!['items'] as String) as List<dynamic>;

void main() {
  tearDown(() async {
    await getIt.reset();
  });

  group('getMyLoad', () {
    test('posts api.order.load.get_my_load and types the load', () async {
      final http = RecordingHttpService.install((_) => {
            'data': [_loadRow()],
          });

      final loads = _data(await DriverLoadRepository().getMyLoad());

      final request = http.single;
      expect(request.method, 'POST');
      expect(request.path, kPlatformGatewayPath);
      expect(request.cmd, 'api.order.load.get_my_load');
      expect(loads, hasLength(1));
      expect(loads.single.shopTitle, 'Depot North');
      expect(loads.single.lines.single.remainingQty, 6);
      expect(loads.single.lines.single.unitTitle, 'bottle');
    });

    test('no load is an empty list, not a failure', () async {
      RecordingHttpService.install((_) => {'data': []});
      expect(_data(await DriverLoadRepository().getMyLoad()), isEmpty);
    });
  });

  group('createLoadSale', () {
    test('posts the load order and the stock lines', () async {
      final http = RecordingHttpService.install((_) => {
            'data': {'order_id': 'ORD-77', 'load': _loadRow()},
          });

      final sale = _data(
        await DriverLoadRepository().createLoadSale(
          loadOrder: 'LOAD-4',
          items: const [
            DriverLoadMovement(stockId: 'STK-1', quantity: 3),
          ],
          note: ' at the gate ',
        ),
      );

      final request = http.single;
      expect(request.cmd, 'api.order.load.create_load_sale');
      expect(request.payload!['load_order'], 'LOAD-4');
      expect(_items(request.payload), [
        {'stock': 'STK-1', 'quantity': 3},
      ]);
      expect(request.payload!['note'], 'at the gate');
      expect(sale.orderId, 'ORD-77');
      expect(sale.load?.id, 'LOAD-4');
    });

    test('a walk-in on the driver own account sends no customer', () async {
      final http = RecordingHttpService.install((_) => {
            'data': {'order_id': 'ORD-78'},
          });

      await DriverLoadRepository().createLoadSale(
        loadOrder: 'LOAD-4',
        items: const [DriverLoadMovement(stockId: 'STK-1', quantity: 1)],
        customer: null,
      );

      expect(http.single.payload!.containsKey('customer'), isFalse);
      // An empty note is absence, not an empty string on the order.
      expect(http.single.payload!.containsKey('note'), isFalse);
    });

    test('a named customer rides the payload when one is given', () async {
      final http = RecordingHttpService.install((_) => {
            'data': {'order_id': 'ORD-79'},
          });

      await DriverLoadRepository().createLoadSale(
        loadOrder: 'LOAD-4',
        items: const [DriverLoadMovement(stockId: 'STK-1', quantity: 1)],
        customer: 'CUST-2',
      );

      expect(http.single.payload!['customer'], 'CUST-2');
    });
  });

  group('returnLoad', () {
    test('posts api.order.load.return_load and reads the load back',
        () async {
      final http = RecordingHttpService.install((_) => {'data': _loadRow()});

      final load = _data(
        await DriverLoadRepository().returnLoad(
          loadOrder: 'LOAD-4',
          items: const [DriverLoadMovement(stockId: 'STK-1', quantity: 2)],
        ),
      );

      expect(http.single.cmd, 'api.order.load.return_load');
      expect(http.single.payload!['load_order'], 'LOAD-4');
      expect(_items(http.single.payload), [
        {'stock': 'STK-1', 'quantity': 2},
      ]);
      expect(load.id, 'LOAD-4');
    });
  });

  group('closeLoad', () {
    test('posts api.order.load.close_load and reads the variance back',
        () async {
      final http = RecordingHttpService.install((_) => {
            'data': {
              'id': 'LOAD-4',
              'load_status': 'Closed',
              'variance_amount': 90,
              'lines': [
                {
                  'stock_id': 'STK-1',
                  'unit_price': 45,
                  'variance_qty': 2,
                  'variance_amount': 90,
                },
              ],
            },
          });

      final load =
          _data(await DriverLoadRepository().closeLoad(loadOrder: 'LOAD-4'));

      expect(http.single.cmd, 'api.order.load.close_load');
      expect(http.single.payload, {'load_order': 'LOAD-4'});
      expect(load.isOpen, isFalse);
      expect(load.varianceTotal, 90);
      expect(load.lines.single.varianceQty, 2);
    });

    test('an empty answer is a failure, never a blank load', () async {
      RecordingHttpService.install((_) => {'data': {}});

      final result = await DriverLoadRepository().closeLoad(
        loadOrder: 'LOAD-4',
      );

      expect(result, isA<Failure<dynamic>>());
    });
  });
}
