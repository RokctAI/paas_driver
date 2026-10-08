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

// Demo runs the REAL orders repositories: base_sdk's DemoGatewayInterceptor
// answers every platform cmd they send from templates/assets/demo/orders.

import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/models/data/order_active_model.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orders_sdk/src/common/infrastructure/repositories/cart_repository.dart';
import 'package:orders_sdk/src/common/infrastructure/repositories/orders_repository.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/collect_conversion.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/order_calculate_data.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/response/create_order_response.dart';
import 'package:orders_sdk/src/manager/infrastructure/repositories/seller_orders_repository.dart';

import 'support/demo_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(startDemoFixtures);
  tearDown(stopDemoFixtures);

  test('customer cart: the demo cart and its edits', () async {
    final repo = CartRepository();
    final cart = ok(await repo.getCart('1'));
    expect(cart.data!.totalPrice, 300);
    expect(cart.data!.userCarts!.single.name, 'Thandi Mokoena');
    expect(cart.data!.userCarts!.single.cartDetails!.single.quantity, 2);
    expect(
      ok(await repo.getCartInGroup('1', '1', 'demo_cart_uuid')).data!.userCarts,
      hasLength(1),
    );
    expect(ok(await repo.deleteCart(cartId: '1')).data!.userCarts, isEmpty);
    expect(
      ok(await repo.removeProductCart(cartDetailId: '101'))
          .data!
          .userCarts!
          .single
          .cartDetails,
      isEmpty,
    );
    ok(await repo.changeStatus(userUuid: 'u', cartId: '1'));
    ok(await repo.deleteUser(cartId: '1', userId: '1'));
  });

  test(
    'customer orders: history, active, completed, detail and money',
    () async {
      final repo = OrdersRepository();
      expect(ok(await repo.getHistoryOrders(1)).data, hasLength(2));
      expect(ok(await repo.getActiveOrders(1)).data!.single.status, 'accepted');
      final done = ok(await repo.getCompletedOrders(1)).data!.single;
      expect(done.shop!.translation?.title, "Nonna's Pizzeria");
      expect(done.currencyModel!.symbol, 'R');
      expect(ok(await repo.getSingleOrder('1')).id, '1');
      final calc = ok(
        await repo.getCalculate(
          cartId: '1',
          lat: 0,
          long: 0,
          type: DeliveryTypeEnum.delivery,
        ),
      );
      expect(calc.totalPrice, 50.0);
      expect(
        ok(await repo.checkCoupon(coupon: 'X', shopId: '1')).data!.price,
        5.0,
      );
      expect(ok(await repo.checkCashback(shopId: '1', amount: 10)).price, 0);
      expect(ok(await repo.getDriverLocation('1')).latitude, 37.7749);
      expect(ok(await repo.getRefundOrders(1)).data, isEmpty);
      expect(
        ok(await repo.tipProcess(orderId: '1', tip: 5)),
        'http://mock-tip-payment-url.com',
      );
      ok(await repo.addReview('1', rating: 5, comment: 'Great'));
      ok(await repo.cancelOrder('1'));
      ok(await repo.refundOrder('1', 'Cold'));
    },
  );

  test('create_order answers both the customer and the seller shape', () async {
    final body = await const PlatformGateway().tenant('api.order.create_order');
    expect(OrderActiveModel.fromJson(body).status, 'pending');
    final created = CreateOrderResponse.fromJson(body).data!;
    expect(created.id, '1042');
    expect(created.price, 150);
  });

  test('manager: the seeded shift, its columns, detail and actions', () async {
    final repo = SellerOrdersRepository();
    final all = ok(await repo.getOrders(page: 1)).data!;
    expect(all.orders, hasLength(7));
    expect(all.statistic!.newOrdersCount, 2);
    final fresh = ok(await repo.getOrders(status: OrderStatus.open, page: 1));
    expect(fresh.data!.orders!.map((o) => o.id), ['1041', '1040']);
    expect(
      ok(await repo.getOrders(rawStatus: 'ready', page: 1))
          .data!
          .orders!
          .single
          .totalPrice,
      415.75,
    );
    expect(ok(await repo.getOrders(page: 2)).data!.orders, isEmpty);
    expect(ok(await repo.getHistoryOrders(page: 1)).data!.orders, hasLength(3));
    final detail = ok(await repo.getOrderDetails(orderId: '1037')).data!;
    expect(detail.deliverymanName, 'Bongani M.');
    expect(detail.currency!.symbol, 'R');
    expect(
      detail.details!.single.stock!.product!.translation?.title,
      'Gatsby (half)',
    );
    expect(
      ok(await repo.updateOrderStatus(rawStatus: 'cooking', orderId: '1041'))
          .data!
          .status,
      'cooking',
    );
    final converted = ok(
      await repo.convertDeliveryToCollected(orderId: '1041'),
    );
    expect(converted.feeOutcome, CollectFeeOutcome.refunded);
    expect(converted.totalPrice, 223.5);
    expect(ok(await repo.getPayments()).data!.map((p) => p.id), [
      'cash',
      'wallet',
    ]);
    ok(await repo.createTransaction(orderId: '1041', paymentId: 'cash'));
    final OrderCalculate calc = ok(
      await repo.getCalculate(stocks: const [], type: 'delivery'),
    );
    expect(calc.data!.deliveryFee, 25);
    expect(calc.data!.totalPrice, 175);
  });

  test('empty lists for loads and the driver roster', () async {
    expect(
      await const PlatformGateway().tenant('api.order.load.get_shop_loads'),
      isEmpty,
    );
  });

  test(
    'merchants\' POS adapter reads the demo customer\'s credit here',
    () async {
      final body = await const PlatformGateway().tenant(
        'api.seller_order.get_seller_orders',
        {
          'order_user': 'demo-customer',
          'payment_status': 'Credit',
          'limit_page_length': 100,
        },
      );
      expect((body as Map)['data'].single['total_price'], 89.5);
    },
  );
}
