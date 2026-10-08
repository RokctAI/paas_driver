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

import 'package:base_sdk/base_sdk.dart' show PushMessages;
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PushMessages', () {
    test('dispatches by data type', () async {
      final pm = PushMessages();
      final seen = <Map<String, dynamic>>[];
      pm.register('order_status', seen.add);
      expect(await pm.dispatch({'type': 'order_status', 'order_id': '1'}),
          isTrue);
      expect(await pm.dispatch({'type': 'chat'}), isFalse);
      expect(await pm.dispatch({'order_id': '1'}), isFalse);
      expect(seen, [
        {'type': 'order_status', 'order_id': '1'},
      ]);
    });

    test('a throwing handler does not escape; unregister removes', () async {
      final pm = PushMessages();
      pm.register('x', (_) => throw StateError('boom'));
      expect(await pm.dispatch({'type': 'x'}), isTrue);
      pm.unregister('x');
      expect(pm.handles('x'), isFalse);
    });
  });

  group('getOrderStatus reads the backend spellings', () {
    test('doctype options, any case', () {
      expect(AppHelpers.getOrderStatus('Shipped'), OrderStatus.onWay);
      expect(AppHelpers.getOrderStatus('on_a_way'), OrderStatus.onWay);
      expect(AppHelpers.getOrderStatus('Cancelled'), OrderStatus.canceled);
      expect(AppHelpers.getOrderStatus('canceled'), OrderStatus.canceled);
      expect(AppHelpers.getOrderStatus('New'), OrderStatus.open);
      expect(AppHelpers.getOrderStatus('Ready'), OrderStatus.ready);
      expect(AppHelpers.getOrderStatus('Delivered'), OrderStatus.delivered);
      expect(AppHelpers.getOrderStatus('Cooking'), OrderStatus.accepted);
      expect(AppHelpers.getOrderStatus('processing'), OrderStatus.accepted);
    });

    test('unknown and null still read as accepted', () {
      expect(AppHelpers.getOrderStatus('teleported'), OrderStatus.accepted);
      expect(AppHelpers.getOrderStatus(null), OrderStatus.accepted);
    });
  });
}
