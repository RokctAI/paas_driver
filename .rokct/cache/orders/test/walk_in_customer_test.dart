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

// THE TWO HALVES OF THE WALK-IN CUSTOMER (fixplan M19 + Ray 2026-09-18
// "in paas_pos i think if seller was making order for walkin customer and
// not input details it then used seller account as customer").
//
// 1. No details entered -> the seller's own account is the customer. The
//    rule is a pure function (`resolveWalkInOrderCustomer`) precisely so it
//    can be asserted here without a till, a session or a socket.
// 2. Details entered -> a REAL server method creates the customer. The
//    create lives in the host adapter (`templates/adapters/manager/`),
//    which cannot be instantiated standalone (it imports merchants_sdk and
//    only exists as composed host code), so the cmd contract is pinned by
//    reading the template — the manifest_wiring_test.dart precedent for
//    guarding what is composition data rather than package code.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orders_sdk/src/manager/domain/walk_in_customer.dart';

void main() {
  group('no details entered -> the seller account is the customer', () {
    test('the seller stands in when nothing was picked', () {
      final customer = resolveWalkInOrderCustomer(
        sellerUserId: 'USR-SELLER',
        sellerPhone: '+27110000001',
      );
      expect(customer.userId, 'USR-SELLER');
      expect(customer.phone, '+27110000001');
      expect(customer.isSellerAccount, isTrue);
    });

    test('a blank pick is no pick', () {
      final customer = resolveWalkInOrderCustomer(
        selectedUserId: '   ',
        selectedPhone: '   ',
        sellerUserId: 'USR-SELLER',
        sellerPhone: '+27110000001',
      );
      expect(customer.userId, 'USR-SELLER');
      expect(customer.isSellerAccount, isTrue);
    });

    test('no pick and no cached seller invents nothing', () {
      final customer = resolveWalkInOrderCustomer();
      expect(customer.userId, isNull);
      expect(customer.phone, isNull);
      expect(customer.isSellerAccount, isFalse);
    });

    test('a seller with no phone on file carries no phone', () {
      final customer = resolveWalkInOrderCustomer(sellerUserId: 'USR-SELLER');
      expect(customer.userId, 'USR-SELLER');
      expect(customer.phone, isNull);
      expect(customer.isSellerAccount, isTrue);
    });
  });

  group('details entered -> the picked/created customer wins', () {
    test('the pick beats the seller account', () {
      final customer = resolveWalkInOrderCustomer(
        selectedUserId: 'USR-WALKIN',
        selectedPhone: '+27110000002',
        sellerUserId: 'USR-SELLER',
        sellerPhone: '+27110000001',
      );
      expect(customer.userId, 'USR-WALKIN');
      expect(customer.phone, '+27110000002');
      expect(customer.isSellerAccount, isFalse);
    });

    test('a picked customer with no phone drops the phone key', () {
      final customer = resolveWalkInOrderCustomer(
        selectedUserId: 'USR-WALKIN',
        sellerPhone: '+27110000001',
      );
      expect(customer.userId, 'USR-WALKIN');
      // Never the seller's phone on someone else's order.
      expect(customer.phone, isNull);
    });
  });

  group('the create-walk-in-customer server method is real', () {
    final adapter = File(
      'templates/adapters/manager/orders_adapters.dart',
    ).readAsStringSync();

    test('createUser calls the whitelisted gateway cmd', () {
      expect(adapter, contains("'api.order.create_walk_in_customer'"));
      // The dead per-method URL and the users_sdk self-signup path are gone.
      expect(adapter, isNot(contains('paas.api.user.user')));
      expect(adapter, isNot(contains('/api/method/')));
    });

    test('orders frappe whitelists that cmd', () {
      final manifest = jsonDecode(
        File('../frappe/manifest.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final methods = (((manifest['app_type'] as Map)['tenant'] as Map)['hooks']
          as Map)['whitelisted_methods'] as Map<String, dynamic>;
      expect(
        methods['{app_name}.api.order.create_walk_in_customer'],
        '{app_name}.orders.tenant.api.order.create_walk_in_customer',
      );
    });
  });
}
