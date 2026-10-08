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

// WebViewPage captures a PayPal REST order when PayPal redirects the payer
// to the wallet's paypal_rest_return URL; this pins how that URL is read.

import 'package:flutter_test/flutter_test.dart';
import 'package:orders_sdk/src/common/infrastructure/repositories/orders_repository.dart';

void main() {
  test('reads the PayPal order id from the REST return URL', () {
    expect(
      OrdersRepository.paypalRestReturnToken(
        'https://shop.test/api/method/rokct.api.payment.paypal_rest_return'
        '?token=5O190127TN364715T&PayerID=ABC',
      ),
      '5O190127TN364715T',
    );
  });

  test('ignores other URLs and a return without a token', () {
    expect(
      OrdersRepository.paypalRestReturnToken('https://shop.test/payment-success'),
      isNull,
    );
    expect(
      OrdersRepository.paypalRestReturnToken(
        'https://shop.test/api/method/rokct.api.payment.paypal_rest_return',
      ),
      isNull,
    );
  });
}
