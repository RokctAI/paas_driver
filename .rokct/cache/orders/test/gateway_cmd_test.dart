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


// Fix-wave 2026-09-02 (G4, fixplan M10/M12-M18): every customer and manager
// repository call that used to hit a dead per-method `/api/method/paas...`
// URL or a Laravel-era `/api/v1/...` path now goes through the universal
// gateway (`POST /api/v1/method/rokct.platform.api`, body `{cmd, payload}`).
// These cases pin the cmd name and payload keys per call - the contract the
// composed backend's whitelist resolves - without opening a socket.
//
// Only the REQUEST is asserted. The canned reply is an empty map, so the
// repositories' model parsing may land on the failure branch; that is not
// what these tests guard (the wire contract is captured before parsing).

import 'dart:convert';
import 'dart:typed_data';

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/handlers/http_service.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/models/data/currency_data.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/models/request/cart_request.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:orders_sdk/src/common/infrastructure/repositories/cart_repository.dart';
import 'package:orders_sdk/src/common/infrastructure/repositories/orders_repository.dart';
import 'package:orders_sdk/src/common/infrastructure/repositories/parcel_repository.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/stock.dart';
import 'package:orders_sdk/src/manager/infrastructure/repositories/pos_products_repository.dart';
import 'package:orders_sdk/src/manager/infrastructure/repositories/seller_orders_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A recording stand-in for base_sdk's [HttpService]: every Dio the
/// repositories ask for answers through [_RecordingAdapter], which captures
/// the gateway envelope (`{cmd, payload}`), the request path and headers, and
/// answers a canned `{"message": ...}` body (unwrapped by the same
/// FrappeResponseInterceptor production uses). No socket is ever opened.
class FakeGatewayHttp extends HttpService {
  final List<RecordedCall> calls = [];
  dynamic reply = <String, dynamic>{};

  RecordedCall get last => calls.last;

  @override
  Dio client({bool requireAuth = false, bool routing = false}) {
    final dio = Dio(BaseOptions(baseUrl: 'https://gateway.test'))
      ..httpClientAdapter = _RecordingAdapter(this, requireAuth)
      ..interceptors.add(const FrappeResponseInterceptor());
    return dio;
  }
}

class RecordedCall {
  final String path;
  final bool requireAuth;
  final Map<String, dynamic> body;
  final Map<String, dynamic> headers;

  RecordedCall(this.path, this.requireAuth, this.body, this.headers);

  String? get cmd => body['cmd'] as String?;
  Map<String, dynamic>? get payload =>
      (body['payload'] as Map?)?.cast<String, dynamic>();
}

class _RecordingAdapter implements HttpClientAdapter {
  final FakeGatewayHttp owner;
  final bool requireAuth;

  _RecordingAdapter(this.owner, this.requireAuth);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final dynamic data = options.data;
    owner.calls.add(RecordedCall(
      options.path,
      requireAuth,
      data is Map ? data.cast<String, dynamic>() : <String, dynamic>{},
      Map<String, dynamic>.from(options.headers),
    ));
    return ResponseBody.fromString(
      jsonEncode({'message': owner.reply}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// The smallest complete checkout body: `process` only reads `cartId`.
OrderBodyData _orderBody(String cartId) => OrderBodyData(
      cartId: cartId,
      shopId: 'SHOP-1',
      paymentId: 'PG-1',
      deliveryFee: 0,
      deliveryType: DeliveryTypeEnum.pickup,
      location: Location(latitude: 0, longitude: 0),
      address: AddressModel(address: ''),
      deliveryDate: '2026-09-03',
      deliveryTime: '12:00',
      notes: const [],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGatewayHttp http;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    await LocalStorage.setSelectedCurrency(
      CurrencyData(id: 'ZAR', symbol: 'R', position: 'before', rate: 1),
    );
  });

  setUp(() {
    http = FakeGatewayHttp();
    if (GetIt.I.isRegistered<HttpService>()) {
      GetIt.I.unregister<HttpService>();
    }
    GetIt.I.registerSingleton<HttpService>(http);
  });

  group('customer cart / order / parcel repositories', () {
    test('insertCartWithGroup wraps the cart under `cart` (M10)', () async {
      await CartRepository().insertCartWithGroup(
        cart: CartRequest(productId: 'p1', quantity: 2, shopId: 's1'),
      );
      expect(http.last.path, kPlatformGatewayPath);
      expect(http.last.cmd, 'api.cart.insert_cart_with_group');
      expect(http.last.payload!.keys, ['cart']);
      expect(http.last.payload!['cart'], isA<Map>());
    });

    test('process initiates the hosted checkout by provider (M12)', () async {
      await OrdersRepository().process(_orderBody('CART-1'), 'PayStack');
      expect(http.last.cmd, 'api.payment.initiate_paystack_payment');
      expect(http.last.payload, {'order_id': 'CART-1'});
    });

    test('process refuses a provider with no initiate_* method (M12)',
        () async {
      final result =
          await OrdersRepository().process(_orderBody('CART-1'), 'payfast');
      expect(http.calls, isEmpty, reason: 'no 404 round trip');
      result.when(
        success: (_) => fail('must not succeed'),
        failure: (error, statusCode) => expect(statusCode, 400),
      );
    });

    test('refunds go through users\' create/get refund cmds (M13)', () async {
      final repo = OrdersRepository();
      await repo.refundOrder('ORD-1', 'wrong item');
      expect(http.last.cmd, 'api.user.create_order_refund');
      expect(http.last.payload, {'order': 'ORD-1', 'cause': 'wrong item'});

      await repo.getRefundOrders(3);
      expect(http.last.cmd, 'api.user.get_user_order_refunds');
      expect(http.last.payload, {'page': 3});
    });

    test('repeating orders always carry the three required kwargs (M14)',
        () async {
      final repo = OrdersRepository();
      await repo.createAutoOrder(from: '2026-09-03', orderId: 'ORD-1');
      expect(http.last.cmd, 'api.repeating_order.create_repeating_order');
      expect(
        http.last.payload,
        containsPair('cron_pattern', '0 0 * * *'),
        reason: 'the server requires cron_pattern; the client defaults it',
      );
      expect(http.last.payload, containsPair('original_order', 'ORD-1'));
      expect(http.last.payload, containsPair('start_date', '2026-09-03'));

      await repo.createRepeatingOrder(
        orderId: 'ORD-1',
        startDate: '2026-09-03',
        cronPattern: '0 9 * * 1',
        endDate: '2026-12-01',
      );
      expect(http.last.payload, {
        'original_order': 'ORD-1',
        'start_date': '2026-09-03',
        'cron_pattern': '0 9 * * 1',
        'end_date': '2026-12-01',
      });

      await repo.pauseAutoOrder('REP-1');
      expect(http.last.cmd, 'api.repeating_order.pause_repeating_order');
      expect(http.last.payload, {'repeating_order_id': 'REP-1'});
      await repo.resumeAutoOrder('REP-1');
      expect(http.last.cmd, 'api.repeating_order.resume_repeating_order');
      await repo.deleteAutoOrder('REP-1');
      expect(http.last.cmd, 'api.repeating_order.delete_repeating_order');
      expect(http.last.payload, {'repeating_order_id': 'REP-1'});
    });

    test('parcel payment + transaction use the wallet cmds (M15)', () async {
      final repo = ParcelRepository();
      await repo.process('PARCEL-1', 'Flutterwave');
      expect(http.last.cmd, 'api.payment.initiate_flutterwave_parcel_payment');
      expect(http.last.payload, {'order_id': 'PARCEL-1'});

      await repo.createTransaction(orderId: 'PARCEL-1', paymentId: 'PG-1');
      expect(http.last.cmd, 'api.payment.create_order_transaction');
      expect(http.last.payload, {
        'order_id': 'PARCEL-1',
        'payment_sys_id': 'PG-1',
      });
    });

    test('parcel process refuses an unknown provider without a call (M15)',
        () async {
      final result = await ParcelRepository().process('PARCEL-1', 'stripe');
      expect(http.calls, isEmpty);
      result.when(
        success: (_) => fail('must not succeed'),
        failure: (error, statusCode) => expect(statusCode, 400),
      );
    });
  });

  group('manager seller orders repository (M16/M17)', () {
    test('lists go through api.seller_order.get_seller_orders', () async {
      final repo = SellerOrdersRepository();
      await repo.getOrders(status: OrderStatus.accepted, page: 2);
      expect(http.last.path, kPlatformGatewayPath);
      expect(http.last.cmd, 'api.seller_order.get_seller_orders');
      expect(http.last.payload, containsPair('limit_start', 10));
      expect(http.last.payload, containsPair('limit_page_length', 10));
      expect(http.last.payload, containsPair('status', 'accepted'));

      await repo.getHistoryOrders(page: 1, from: '2026-09-01');
      expect(http.last.cmd, 'api.seller_order.get_seller_orders');
      expect(http.last.payload, containsPair('status', 'delivered'));
      expect(http.last.payload, containsPair('from_date', '2026-09-01'));
    });

    test('details and status updates name the order', () async {
      final repo = SellerOrdersRepository();
      await repo.getOrderDetails(orderId: 'ORD-9');
      expect(http.last.cmd, 'api.seller_order.get_seller_order_details');
      expect(http.last.payload, containsPair('order_id', 'ORD-9'));

      await repo.updateOrderStatus(orderId: 'ORD-9', status: OrderStatus.ready);
      expect(http.last.cmd, 'api.seller_order.update_seller_order_status');
      expect(http.last.payload, {'order_id': 'ORD-9', 'status': 'ready'});
    });

    test('createTransaction is the wallet create_order_transaction cmd',
        () async {
      await SellerOrdersRepository().createTransaction(
        orderId: 'ORD-9',
        paymentId: 'PG-1',
      );
      expect(http.last.cmd, 'api.payment.create_order_transaction');
      expect(http.last.payload, {'order_id': 'ORD-9', 'payment_sys_id': 'PG-1'});
      expect(http.last.requireAuth, isTrue);
    });

    test('getCalculate sends a JSON products list (M17)', () async {
      await SellerOrdersRepository().getCalculate(
        stocks: [Stock(id: 'STK-1', cartCount: 3)],
        type: 'pickup',
      );
      expect(http.last.cmd, 'api.product.order_products_calculate');
      final products = http.last.payload!['products'] as List;
      expect(products, hasLength(1));
      expect(products.first, containsPair('product_id', 'STK-1'));
      expect(products.first, containsPair('stock_id', 'STK-1'));
      expect(products.first, containsPair('quantity', 3));
      expect(http.last.payload, containsPair('type', 'pickup'));
    });
  });

  group('POS products repository (M18)', () {
    test('reads go through the merchants seller_product cmds', () async {
      final repo = PosProductsRepository();
      await repo.getProducts(page: 2, categoryId: 'CAT-1');
      expect(http.last.cmd, 'api.seller_product.get_seller_products');
      expect(http.last.payload, containsPair('limit_start', 20));
      expect(http.last.payload, containsPair('limit_page_length', 20));
      expect(http.last.payload, containsPair('category_id', 'CAT-1'));
      expect(http.last.payload, containsPair('active', 1));

      await repo.getShopCategories(page: 1);
      expect(http.last.cmd, 'api.seller_product.get_seller_categories');
      expect(http.last.payload, containsPair('limit_start', 0));

      await repo.getProductDetails('PROD-1');
      expect(http.last.cmd, 'api.seller_product.get_product_details');
      expect(http.last.payload, containsPair('product_name', 'PROD-1'));
    });
  });

  group('gateway envelope', () {
    test('an idempotency header rides on the gateway POST', () async {
      await const PlatformGateway().call(
        'api.payment.create_order_transaction',
        payload: {'order_id': 'ORD-1', 'payment_sys_id': 'PG-1'},
        options: Options(headers: {'X-Idempotency-Key': 'op-1:txn'}),
      );
      expect(http.last.path, kPlatformGatewayPath);
      expect(http.last.headers, containsPair('X-Idempotency-Key', 'op-1:txn'));
    });
  });
}
