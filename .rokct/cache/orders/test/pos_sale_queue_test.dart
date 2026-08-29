// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// PosSaleQueue's create_order body contract (the POS -> seller-pipeline
// handoff), and ManagerOrdersLocalStore.toOrderData's status fidelity
// (queue rows carry the sale's REAL status; legacy bodies keep 'new').

import 'package:base_sdk/src/models/data/currency_data.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orders_sdk/src/manager/infrastructure/services/manager_orders_local_store.dart';
import 'package:orders_sdk/src/manager/infrastructure/services/pos_sale_queue.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    await LocalStorage.setSelectedCurrency(
      CurrencyData(id: 'ZAR', symbol: 'R', position: 'before', rate: 1),
    );
  });

  group('PosSaleQueue.buildOrderBody', () {
    test('carries the canonical backend contract with the POS additions',
        () {
      final body = PosSaleQueue.buildOrderBody(
        offlineUuid: 'POS-1756400000000-0042',
        lines: const [
          PosSaleLine(productId: 'prod-a', quantity: 2),
          PosSaleLine(productId: 'prod-b', quantity: 0.75),
        ],
        deliveryType: 'delivery',
        status: 'ready',
        quotedTotal: 325.88,
        userId: 'customer-1',
        phone: '+27721148890',
        address: '12 Marigold Ave, Rosebank',
        paidNow: 200.0,
        onCredit: true,
      );
      expect(body['status'], 'ready');
      expect(body['delivery_type'], 'delivery');
      expect(body['payment_status'], 'Credit');
      expect(body['paid_now'], 200.0);
      expect(body['quoted_total'], 325.88);
      expect(body['user'], 'customer-1');
      expect(body['phone'], '27721148890'); // '+' stripped, legacy rule
      expect(body['address'], {'address': '12 Marigold Ave, Rosebank'});
      expect(body['offline_uuid'], 'POS-1756400000000-0042');
      expect(body['currency'], 'ZAR');
      expect(body['order_items'], [
        {'product': 'prod-a', 'quantity': 2.0},
        {'product': 'prod-b', 'quantity': 0.75},
      ]);
    });

    test('a plain fully-paid in-store sale omits the credit keys', () {
      final body = PosSaleQueue.buildOrderBody(
        offlineUuid: 'POS-1',
        lines: const [PosSaleLine(productId: 'prod-a', quantity: 1)],
        deliveryType: 'pickup',
        status: 'delivered',
        quotedTotal: 150.0,
        paidNow: 150.0,
      );
      expect(body['status'], 'delivered');
      expect(body.containsKey('payment_status'), isFalse);
      expect(body['paid_now'], 150.0);
      expect(body.containsKey('user'), isFalse);
      expect(body.containsKey('address'), isFalse);
    });
  });

  group('ManagerOrdersLocalStore.toOrderData', () {
    test('carries the ACTUAL status the stored body holds', () {
      final row = ManagerOrdersLocalStore.toOrderData({
        'local_id': 'offline:abc',
        'order': {'status': 'ready', 'delivery_type': 'delivery'},
        'synced': false,
      });
      expect(row.status, 'ready');
      expect(row.pendingSync, isTrue);
    });

    test('legacy bodies without a status keep the old new-row behavior',
        () {
      final row = ManagerOrdersLocalStore.toOrderData({
        'local_id': 'offline:abc',
        'order': {'delivery_type': 'pickup'},
        'synced': false,
      });
      expect(row.status, 'new');
    });
  });
}
