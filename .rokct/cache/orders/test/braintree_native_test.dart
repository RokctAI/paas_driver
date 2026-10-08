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

// Native Braintree checkout seam: orders_sdk reaches payments_sdk's drop-in
// by a GetIt name, pays natively only on Android/iOS, and hands back null
// (keep the existing WebView path) whenever the native flow cannot run.

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:orders_sdk/src/common/infrastructure/repositories/orders_repository.dart';

void main() {
  late GetIt getIt;
  final List<List<String>> calls = [];

  setUp(() {
    getIt = GetIt.asNewInstance();
    calls.clear();
  });

  void register(Map<String, Object?> answer) {
    Future<Map<String, Object?>> seam(String type, String id) async {
      calls.add([type, id]);
      return answer;
    }

    getIt.registerSingleton<BraintreeNativeSeam>(
      seam,
      instanceName: OrdersRepository.braintreeNativeSeam,
    );
  }

  test('braintree tags are recognised, other gateways are not', () {
    expect(OrdersRepository.isBraintree('braintree'), isTrue);
    expect(OrdersRepository.isBraintree('Braintree-Main'), isTrue);
    expect(OrdersRepository.isBraintree('paypal'), isFalse);
    expect(
      OrdersRepository.hostedCheckoutProviders,
      containsAll(['flutterwave', 'paypal', 'paystack']),
    );
  });

  test('web/Windows: no native call, existing path kept', () async {
    register({'status': 'success'});
    final r = await OrdersRepository.braintreeNative(
      'order',
      'ORD-1',
      getIt: getIt,
      platformOk: false,
    );
    expect(r, isNull);
    expect(calls, isEmpty);
  });

  test('payments_sdk not composed: existing path kept', () async {
    final r = await OrdersRepository.braintreeNative(
      'order',
      'ORD-1',
      getIt: getIt,
      platformOk: true,
    );
    expect(r, isNull);
  });

  test('native success answers the paid marker', () async {
    register({'status': 'success', 'transaction_id': 'T'});
    final r = await OrdersRepository.braintreeNative(
      'parcel',
      'P-1',
      getIt: getIt,
      platformOk: true,
    );
    expect(calls, [
      ['parcel', 'P-1'],
    ]);
    expect((r! as Success<String>).data, OrdersRepository.braintreeNativePaid);
  });

  test('unavailable falls back, a refusal does not', () async {
    register({'status': 'unavailable'});
    expect(
      await OrdersRepository.braintreeNative(
        'order',
        'ORD-1',
        getIt: getIt,
        platformOk: true,
      ),
      isNull,
    );
    getIt = GetIt.asNewInstance();
    register({'status': 'failed', 'message': 'Do Not Honor'});
    final r = await OrdersRepository.braintreeNative(
      'order',
      'ORD-1',
      getIt: getIt,
      platformOk: true,
    );
    expect((r! as Failure<String>).error, 'Do Not Honor');
  });

  test('a throwing seam falls back', () async {
    Future<Map<String, Object?>> seam(String a, String b) async =>
        throw StateError('boom');
    getIt.registerSingleton<BraintreeNativeSeam>(
      seam,
      instanceName: OrdersRepository.braintreeNativeSeam,
    );
    expect(
      await OrdersRepository.braintreeNative(
        'order',
        'ORD-1',
        getIt: getIt,
        platformOk: true,
      ),
      isNull,
    );
  });
}
