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

// The van-sales contract as commerce's `api.order.load.*` defs answer it,
// pinned shape by shape.
//
// What these tests are really defending: a serializer that has not caught
// up must degrade to a BLANK, never to a crash. A driver whose phone
// throws on a missing key cannot sell anything at all, so every field is
// read tolerantly and every one of those tolerances is pinned here.

import 'package:delivery_sdk/src/driver/infrastructure/models/data/driver_load.dart';
import 'package:flutter_test/flutter_test.dart';

/// One load exactly as the contract describes it.
Map<String, dynamic> _loadJson() => {
      'id': 'LOAD-4',
      'shop': {'id': 'SHOP-1', 'title': 'Depot North'},
      'load_status': 'Open',
      'created_at': '2026-09-18 06:10:00',
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
            'id': 12,
            'uuid': 'PRD-WATER-5L',
            'translation': {'title': 'Still water 5L'},
            'img': '/files/water.png',
            'unit': {
              'id': 'UNIT-BOTTLE',
              'translation': {'title': 'bottle'},
            },
          },
        },
        {
          'item_id': 'LI-2',
          'stock_id': 'STK-2',
          'unit_price': 20,
          'issued_qty': 4,
          'sold_qty': 4,
          'returned_qty': 0,
          'remaining_qty': 0,
          'product': {
            'id': 13,
            'uuid': 'PRD-ICE-2KG',
            'translation': {'title': 'Ice 2kg'},
            'img': null,
            'unit': {'translation': {'title': 'bag'}},
          },
        },
      ],
    };

void main() {
  group('DriverLoad.fromJson', () {
    test('reads the contract shape whole', () {
      final load = DriverLoad.fromJson(_loadJson());

      expect(load.id, 'LOAD-4');
      expect(load.shopId, 'SHOP-1');
      expect(load.shopTitle, 'Depot North');
      expect(load.loadStatus, 'Open');
      expect(load.createdAt, '2026-09-18 06:10:00');
      expect(load.lines, hasLength(2));

      final first = load.lines.first;
      expect(first.itemId, 'LI-1');
      expect(first.stockId, 'STK-1');
      expect(first.productId, 12);
      expect(first.productUuid, 'PRD-WATER-5L');
      expect(first.title, 'Still water 5L');
      expect(first.img, '/files/water.png');
      expect(first.unitTitle, 'bottle');
      expect(first.unitPrice, 45);
      expect(first.issuedQty, 10);
      expect(first.soldQty, 3);
      expect(first.returnedQty, 1);
      expect(first.remainingQty, 6);
      // No close has happened, so there is no variance to speak of.
      expect(first.varianceQty, isNull);
      expect(first.varianceAmount, isNull);
    });

    test('a unit sent without an id still gives up its word', () {
      final load = DriverLoad.fromJson(_loadJson());
      expect(load.lines[1].unitTitle, 'bag');
    });

    test('a bare string unit is read as the word itself', () {
      final json = _loadJson();
      (json['lines'] as List)[0]['product']['unit'] = 'bottle';
      expect(DriverLoad.fromJson(json).lines.first.unitTitle, 'bottle');
    });

    test('remainingTotal values the van at the load prices', () {
      // 6 x 45 + 0 x 20.
      expect(DriverLoad.fromJson(_loadJson()).remainingTotal, 270);
      expect(DriverLoad.fromJson(_loadJson()).remainingQtyTotal, 6);
    });

    test('only lines with stock and remaining can be sold from', () {
      final load = DriverLoad.fromJson(_loadJson());
      expect(load.sellableLines.map((l) => l.stockId), ['STK-1']);
    });

    test('a line with no stock row is never sellable', () {
      final json = _loadJson();
      (json['lines'] as List)[0].remove('stock_id');
      final load = DriverLoad.fromJson(json);
      expect(load.lines.first.hasRemaining, isFalse);
      expect(load.sellableLines, isEmpty);
    });

    test('an empty row degrades to blanks rather than throwing', () {
      final load = DriverLoad.fromJson(const {});
      expect(load.id, '');
      expect(load.shopTitle, isNull);
      expect(load.loadStatus, isNull);
      expect(load.lines, isEmpty);
      expect(load.remainingTotal, 0);
      // Nothing has said the load is finished, so it is still his to work.
      expect(load.isOpen, isTrue);
    });

    test('a line missing every quantity reads as zeros', () {
      final load = DriverLoad.fromJson({
        'id': 'LOAD-9',
        'lines': [
          {'stock_id': 'STK-9'},
        ],
      });
      final line = load.lines.single;
      expect(line.unitPrice, 0);
      expect(line.issuedQty, 0);
      expect(line.soldQty, 0);
      expect(line.returnedQty, 0);
      expect(line.remainingQty, 0);
      expect(line.title, isNull);
      expect(line.unitTitle, isNull);
    });

    test('numeric strings from a form-encoded shell are still numbers', () {
      final load = DriverLoad.fromJson({
        'id': 'LOAD-3',
        'lines': [
          {
            'stock_id': 'STK-3',
            'unit_price': '12.50',
            'remaining_qty': '4',
            'issued_qty': '4',
          },
        ],
      });
      expect(load.lines.single.unitPrice, 12.5);
      expect(load.lines.single.remainingQty, 4);
      expect(load.remainingTotal, 50);
    });

    test('closed and cancelled take the load off the driver screen', () {
      for (final status in ['Closed', 'closed', 'Cancelled', 'canceled']) {
        final load = DriverLoad.fromJson({'id': 'L', 'load_status': status});
        expect(load.isOpen, isFalse, reason: status);
      }
      expect(
        DriverLoad.fromJson({'id': 'L', 'load_status': 'Issued'}).isOpen,
        isTrue,
      );
    });
  });

  group('close_load shape', () {
    Map<String, dynamic> closedJson() => {
          'id': 'LOAD-4',
          'load_status': 'Closed',
          'variance_amount': 90,
          'lines': [
            {
              'stock_id': 'STK-1',
              'unit_price': 45,
              'issued_qty': 10,
              'sold_qty': 7,
              'returned_qty': 1,
              'remaining_qty': 0,
              'variance_qty': 2,
              'variance_amount': 90,
            },
          ],
        };

    test('per-line variance and the served total are read', () {
      final load = DriverLoad.fromJson(closedJson());
      expect(load.isOpen, isFalse);
      expect(load.lines.single.varianceQty, 2);
      expect(load.lines.single.varianceAmount, 90);
      expect(load.varianceTotal, 90);
      expect(load.varianceQtyTotal, 2);
    });

    test('a nested totals block is read too', () {
      final json = closedJson()..remove('variance_amount');
      json['totals'] = {'variance_amount': 90, 'sold_total': 315};
      final load = DriverLoad.fromJson(json);
      expect(load.varianceTotal, 90);
      expect(load.totals['sold_total'], 315);
    });

    test('with no served total the per-line amounts are summed', () {
      final json = closedJson()..remove('variance_amount');
      expect(DriverLoad.fromJson(json).varianceTotal, 90);
    });

    test('a load closed with nothing missing charges nothing', () {
      final load = DriverLoad.fromJson({
        'id': 'LOAD-5',
        'load_status': 'Closed',
        'lines': [
          {'stock_id': 'STK-1', 'unit_price': 45, 'variance_qty': 0},
        ],
      });
      expect(load.varianceTotal, 0);
    });
  });

  group('envelopes', () {
    test('listFrom peels the repo{"data": [...]} envelope', () {
      final loads = DriverLoad.listFrom({
        'data': [_loadJson()],
      });
      expect(loads, hasLength(1));
      expect(loads.single.id, 'LOAD-4');
    });

    test('listFrom tolerates a bare list and a stray message wrapper', () {
      expect(DriverLoad.listFrom([_loadJson()]).single.id, 'LOAD-4');
      expect(
        DriverLoad.listFrom({
          'message': {
            'data': [_loadJson()],
          },
        }).single.id,
        'LOAD-4',
      );
    });

    test('an empty or unexpected body is no loads, not a crash', () {
      expect(DriverLoad.listFrom(null), isEmpty);
      expect(DriverLoad.listFrom(const {'data': []}), isEmpty);
      expect(DriverLoad.listFrom('unexpected'), isEmpty);
    });

    test('oneFrom reads a single load out of the envelope', () {
      final load = DriverLoad.oneFrom({'data': _loadJson()});
      expect(load, isNotNull);
      expect(load!.id, 'LOAD-4');
      expect(DriverLoad.oneFrom(const {'data': {}}), isNull);
      expect(DriverLoad.oneFrom(null), isNull);
    });
  });

  group('DriverLoadSale.fromJson', () {
    test('carries the order id and the load as it now stands', () {
      final sale = DriverLoadSale.fromJson({
        'data': {
          'order_id': 'ORD-77',
          'load': _loadJson(),
        },
      });
      expect(sale.orderId, 'ORD-77');
      expect(sale.load?.id, 'LOAD-4');
      // The amount is struck by the caller, not by the server.
      expect(sale.amount, 0);
      expect(sale.withAmount(270).amount, 270);
      expect(sale.withAmount(270).orderId, 'ORD-77');
    });

    test('a sale answered without a load is still a sale', () {
      final sale = DriverLoadSale.fromJson({
        'data': {'order_id': 'ORD-78'},
      });
      expect(sale.orderId, 'ORD-78');
      expect(sale.load, isNull);
    });

    test('a numeric order id is read as its text', () {
      final sale = DriverLoadSale.fromJson({
        'data': {'order_id': 77},
      });
      expect(sale.orderId, '77');
    });
  });
}
