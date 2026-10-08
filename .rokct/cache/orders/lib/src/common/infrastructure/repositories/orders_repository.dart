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

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:base_sdk/src/domain/interface/orders.dart';
import 'package:base_sdk/src/models/data/order_active_model.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/enums.dart';

/// payments_sdk's native Braintree checkout: `(targetType, targetId)` ->
/// `{status: success|failed|cancelled|unavailable, message?, transaction_id?}`.
typedef BraintreeNativeSeam = Future<Map<String, Object?>> Function(
  String targetType,
  String targetId,
);

class OrdersRepository implements OrdersRepositoryFacade {
  /// Universal platform gateway (fleet rule 2026-08-15): cmds mirror the
  /// owning modules' `manifest.json` whitelisted-method keys with the app
  /// segment dropped (`api.order.*`, `api.coupon.*`, `api.shop.*`,
  /// `api.payment.*`, `api.delivery.*`, `api.user.*`, `api.repeating_order.*`).
  static const _gateway = PlatformGateway();

  /// The gateway interceptor already strips Frappe's `{"message": ...}`
  /// envelope once. What is left is either the bare return value or the
  /// orders/merchants `api_response` shape (`{data, message?, status_code}`).
  /// Tolerates a still-wrapped `message` (same pattern as
  /// shop_loads_repository `_unwrap`) and peels the `api_response` `data`.
  static Object? _payload(dynamic response) {
    Object? body = response;
    if (body is Map &&
        body.containsKey('message') &&
        !body.containsKey('data') &&
        !body.containsKey('status_code')) {
      body = body['message'];
    }
    if (body is Map &&
        body.containsKey('data') &&
        (body.containsKey('status_code') || body.length == 1)) {
      body = body['data'];
    }
    return body;
  }

  static Map<String, dynamic> _payloadMap(dynamic response) {
    final Object? body = _payload(response);
    if (body is Map) return body.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  /// Maps the customer checkout body onto the canonical
  /// `create_order(order_data)` contract the backend reads (`shop`,
  /// `currency`, `coupon_code`; `user` defaults to the session user
  /// server-side). The legacy keys ride along so nothing that still reads
  /// them loses data.
  static Map<String, dynamic> createOrderPayload(OrderBodyData orderBody) {
    final Map<String, dynamic> body =
        Map<String, dynamic>.from(orderBody.toJson().cast<String, dynamic>());
    body['shop'] ??= body['shop_id'];
    if (body['currency_id'] != null) body['currency'] ??= body['currency_id'];
    if (body['coupon'] != null) body['coupon_code'] ??= body['coupon'];
    return {'order_data': body};
  }

  /// Normalises a raw Order row (list_orders) or `as_dict` document
  /// (get_order_details / create_order) into the shape base_sdk's
  /// [OrderActiveModel] parsers expect: docname -> `id`, Link fields that
  /// arrive as plain strings (`shop`, `user`, `deliveryman`, `currency`)
  /// are turned into maps or dropped instead of being fed to `fromJson`
  /// (which throws on a String), `location`/`address` Data fields are
  /// decoded, and the timestamp / details keys the parsers dereference
  /// unconditionally are always present.
  static Map<String, dynamic> normaliseOrder(Map raw) {
    final Map<String, dynamic> o = Map<String, dynamic>.from(
      raw.cast<String, dynamic>(),
    );
    o['id'] ??= o['name'];
    final Object? shop = o['shop'];
    if (shop is String) o['shop'] = <String, dynamic>{'id': shop};
    final Object? user = o['user'];
    if (user is String) {
      o['user_id'] ??= user;
      o.remove('user');
    }
    if (o['deliveryman'] is String) o.remove('deliveryman');
    if (o['currency'] is String) o.remove('currency');
    Object? location = o['location'];
    if (location is String) {
      try {
        location = jsonDecode(location);
      } catch (_) {
        location = null;
      }
    }
    if (location is Map) {
      o['location'] = location.cast<String, dynamic>();
    } else {
      o.remove('location');
    }
    final Object? address = o['address'];
    if (address is String) {
      Object? decoded;
      try {
        decoded = jsonDecode(address);
      } catch (_) {
        decoded = null;
      }
      o['address'] = decoded is Map
          ? decoded.cast<String, dynamic>()
          : <String, dynamic>{'address': address};
    } else if (address is! Map) {
      o.remove('address');
    }
    o['created_at'] = (o['created_at'] ?? o['creation'])?.toString() ?? '';
    o['updated_at'] = (o['updated_at'] ?? o['modified'])?.toString() ?? '';
    if (o['details'] is! List) {
      final Object? items = o['order_items'];
      o['details'] = <Map<String, dynamic>>[
        if (items is List)
          for (final item in items)
            if (item is Map)
              {
                'id': item['name'],
                'order_id': o['id'],
                'stock_id': item['product'],
                'quantity': item['quantity'],
                'origin_price': item['price'],
                'total_price': (item['price'] is num &&
                        item['quantity'] is num)
                    ? (item['price'] as num) * (item['quantity'] as num)
                    : item['price'],
                'created_at': (item['creation'] ?? o['created_at']).toString(),
                'updated_at': (item['modified'] ?? o['updated_at']).toString(),
              },
      ];
    }
    return o;
  }

  static OrderActiveModel _order(dynamic response) =>
      OrderActiveModel.fromJson({'data': normaliseOrder(_payloadMap(response))});

  /// The hosted checkouts the wallet frappe half serves: Flutterwave and
  /// Paystack through `api.payment.initiate_{flutterwave|paystack}_payment`,
  /// PayPal through the REST Orders v2 `api.payment.create_paypal_rest_order`
  /// (the hosted `initiate_paypal_payment` is retired). Any other gateway
  /// name (PayFast, Stripe, ...) has no hosted checkout, so the call is
  /// refused client-side with a clear failure instead of a 404.
  static const Set<String> hostedCheckoutProviders = {
    'flutterwave',
    'paypal',
    'paystack',
  };

  /// GetIt instance name of payments_sdk's native Braintree checkout
  /// (`BraintreeNativeCheckout.seam`, registered as a
  /// [BraintreeNativeSeam]). orders_sdk does not import payments_sdk; the
  /// function type is structural, so the same registration resolves here.
  static const String braintreeNativeSeam =
      'payments.braintree_native_checkout';

  /// What [process] answers instead of a URL when the native Braintree
  /// drop-in already paid the document. Callers treat it as paid and open
  /// no WebView.
  static const String braintreeNativePaid = 'native-paid://braintree';

  /// A Braintree gateway tag (`braintree`, `braintree-main`, ...).
  static bool isBraintree(String name) =>
      name.toLowerCase().startsWith('braintree');

  /// Android and iOS only: flutter_braintree has no web or desktop build.
  static bool get nativeCheckoutPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static bool braintreeNativeAvailable({GetIt? getIt, bool? platformOk}) =>
      (platformOk ?? nativeCheckoutPlatform) &&
      (getIt ?? GetIt.I).isRegistered<BraintreeNativeSeam>(
        instanceName: braintreeNativeSeam,
      );

  /// Pays [targetType] (`order` / `parcel`) [targetId] with the native
  /// Braintree drop-in. Answers [braintreeNativePaid] on success and a
  /// failure when the payer cancelled or the charge was refused. Answers
  /// null when the native flow is unavailable here or threw before a
  /// payment was attempted: the caller then keeps its existing WebView path.
  static Future<ApiResult<String>?> braintreeNative(
    String targetType,
    String targetId, {
    GetIt? getIt,
    bool? platformOk,
  }) async {
    final GetIt locator = getIt ?? GetIt.I;
    if (!braintreeNativeAvailable(getIt: locator, platformOk: platformOk)) {
      return null;
    }
    try {
      final BraintreeNativeSeam seam = locator<BraintreeNativeSeam>(
        instanceName: braintreeNativeSeam,
      );
      final Map<String, Object?> result = await seam(targetType, targetId);
      switch (result['status']) {
        case 'success':
          return const ApiResult.success(data: braintreeNativePaid);
        case 'cancelled':
          return ApiResult.failure(
            error: AppHelpers.getTranslation('payment_cancelled'),
            statusCode: 400,
          );
        case 'failed':
          return ApiResult.failure(
            error:
                result['message']?.toString() ??
                AppHelpers.getTranslation('payment.rejected'),
            statusCode: 402,
          );
        default:
          return null;
      }
    } catch (e) {
      debugPrint('==> braintree native checkout unavailable: $e');
      return null;
    }
  }

  /// PayPal REST checkout for an Order / Parcel Order: the wallet creates
  /// an Orders v2 order for the document (amount from the document) and
  /// answers its approval link, which the caller opens in [WebViewPage].
  /// On return the WebView captures it with `capture_paypal_rest_order`
  /// (and the server's `paypal_rest_return` / webhook capture it when the
  /// payer returns in an external browser); the capture marks it Paid.
  /// The PayPal order id when [url] is the wallet's PayPal REST return
  /// (`...api.payment.paypal_rest_return?token=<order id>&PayerID=...`).
  static String? paypalRestReturnToken(String url) {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null || !uri.path.contains('paypal_rest_return')) return null;
    final String? token = uri.queryParameters['token'];
    return (token == null || token.isEmpty) ? null : token;
  }

  static Future<String> createPaypalRestOrder(
    String targetType,
    String targetId,
  ) async {
    final response = await const PlatformGateway().tenant(
      'api.payment.create_paypal_rest_order',
      {'target_type': targetType, 'target_id': targetId},
    );
    final Object? url = response is Map ? response['approve_url'] : null;
    if (url == null || url.toString().isEmpty) {
      throw Exception('PayPal did not return an approval link');
    }
    return url.toString();
  }

  @override
  Future<ApiResult<OrderActiveModel>> createOrder(
    OrderBodyData orderBody,
  ) async {
    try {
      final response = await _gateway.tenant(
        'api.order.create_order',
        createOrderPayload(orderBody),
      );
      return ApiResult.success(data: _order(response));
    } catch (e) {
      return ApiResult.failure(
        error: _mapAdultGateError(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  /// Maps the backend 18+ gate markers from `create_order` onto friendly,
  /// translatable messages; anything else falls through to the standard
  /// error handler. Keys are wire-key strings (declared in this SDK's
  /// manifest tr_keys) because lib/ analyzes against raw base_sdk where
  /// composer-injected TrKeys constants don't exist.
  static String _mapAdultGateError(Object e) {
    final String raw = AppHelpers.errorHandler(e);
    final String probe = '$raw $e';
    if (probe.contains('UNDERAGE_PURCHASE_BLOCKED')) {
      return AppHelpers.getTranslation(
        'you_must_be_18_or_older_to_order_adults_only_items',
      );
    }
    if (probe.contains('AGE_VERIFICATION_REQUIRED')) {
      return AppHelpers.getTranslation(
        'age_verification_is_required_to_order_adults_only_items',
      );
    }
    return raw;
  }

  Future<ApiResult<OrderPaginateResponse>> getOrders({
    required int page,
    String? status,
  }) async {
    final data = {
      'page': page,
      'limit_page_length': 10,
      if (status != null) 'status': status,
    };
    try {
      final response = await _gateway.tenant('api.order.list_orders', data);
      final Object? rows = _payload(response);
      return ApiResult.success(
        data: OrderPaginateResponse.fromJson({
          'data': [
            if (rows is List)
              for (final row in rows)
                if (row is Map) normaliseOrder(row),
          ],
          if (response is Map && response['meta'] != null)
            'meta': response['meta'],
        }),
      );
    } catch (e) {
      debugPrint('==> get orders failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<OrderActiveModel>> getSingleOrder(String orderId) async {
    try {
      final response = await _gateway.tenant(
        'api.order.get_order_details',
        {'order_id': orderId},
      );
      return ApiResult.success(data: _order(response));
    } catch (e, s) {
      debugPrint('==> get single order failure: $e,$s');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<void>> addReview(
    String orderId, {
    required double rating,
    required String comment,
  }) async {
    final data = {
      'order_id': orderId,
      'rating': rating,
      if (comment.isNotEmpty) 'comment': comment,
    };
    try {
      await _gateway.tenant('api.order.add_order_review', data);
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> add order review failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<String>> process(
    OrderBodyData orderBody,
    String name, {
    BuildContext? context,
    bool forceCardPayment = false,
    bool enableTokenization = false,
  }) async {
    final String provider = name.toLowerCase();
    if (isBraintree(provider) && braintreeNativeAvailable()) {
      // Native Braintree drop-in on Android/iOS. When it cannot run the
      // existing path below is used unchanged.
      try {
        final created = await _gateway.tenant(
          'api.order.create_order',
          createOrderPayload(orderBody),
        );
        final Map<String, dynamic> order = _payloadMap(created);
        final String? orderName = (order['name'] ?? order['id'])?.toString();
        if (orderName != null && orderName.isNotEmpty) {
          final native = await braintreeNative('order', orderName);
          if (native != null) return native;
        }
      } catch (e) {
        debugPrint('==> braintree native order failure: $e');
        return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e),
        );
      }
    }
    if (!hostedCheckoutProviders.contains(provider)) {
      return ApiResult.failure(
        error: 'No hosted checkout is available for "$name" on this backend',
        statusCode: 400,
      );
    }
    try {
      // wallet's payment.initiate_<provider>_payment(order_id) loads
      // frappe.get_doc("Order", order_id), so the Order must exist first:
      // create it, then initiate the hosted checkout with its real docname
      // (the cart id is not an Order name and made every initiate 404).
      final created = await _gateway.tenant(
        'api.order.create_order',
        createOrderPayload(orderBody),
      );
      final Map<String, dynamic> order = _payloadMap(created);
      final String? orderName = (order['name'] ?? order['id'])?.toString();
      if (orderName == null || orderName.isEmpty) {
        return ApiResult.failure(
          error: 'The order could not be created for checkout',
          statusCode: 400,
        );
      }
      if (provider == 'paypal') {
        return ApiResult.success(
          data: await createPaypalRestOrder('order', orderName),
        );
      }
      final response = await _gateway.tenant(
        'api.payment.initiate_${provider}_payment',
        {'order_id': orderName},
      );
      return ApiResult.success(data: response['redirect_url']);
    } catch (e, s) {
      debugPrint('==> order process failure: $e, $s');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<void>> cancelOrder(String orderId) async {
    try {
      await _gateway.tenant('api.order.cancel_order', {'order_id': orderId});
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> get cancel order failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<void>> refundOrder(String orderId, String title) async {
    try {
      // users' user.create_order_refund(order, cause).
      await _gateway.tenant(
        'api.user.create_order_refund',
        {'order': orderId, 'cause': title},
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> refund order failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult> createAutoOrder({
    required String from,
    required String orderId,
    String? to,
    String? cronPattern,
    String? paymentMethod,
    String? savedCardId,
  }) async {
    try {
      // orders' repeating_order.create_repeating_order requires
      // original_order, start_date AND cron_pattern; a caller that gives no
      // pattern gets the daily-at-midnight default rather than a TypeError.
      await _gateway.tenant(
        'api.repeating_order.create_repeating_order',
        {
          'original_order': orderId,
          'start_date': from,
          'cron_pattern': cronPattern ?? '0 0 * * *',
          if (to != null) 'end_date': to,
          if (paymentMethod != null) 'payment_method': paymentMethod,
          if (savedCardId != null) 'saved_card': savedCardId,
        },
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult> pauseAutoOrder(String autoOrderId) async {
    try {
      await _gateway.tenant(
        'api.repeating_order.pause_repeating_order',
        {'repeating_order_id': autoOrderId},
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult> resumeAutoOrder(String autoOrderId) async {
    try {
      await _gateway.tenant(
        'api.repeating_order.resume_repeating_order',
        {'repeating_order_id': autoOrderId},
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult> deleteAutoOrder(String orderId) async {
    return deleteRepeatingOrder(repeatingOrderId: orderId);
  }

  @override
  Future<ApiResult<RefundOrdersModel>> getRefundOrders(int page) async {
    try {
      // users' user.get_user_order_refunds(page) — the legacy GET query
      // becomes the cmd payload; the gateway answers the method's own
      // (already interceptor-unwrapped) body, so no second unwrap.
      final response = await _gateway.tenant(
        'api.user.get_user_order_refunds',
        {'page': page},
      );
      return ApiResult.success(data: RefundOrdersModel.fromJson(response));
    } catch (e) {
      debugPrint('==> get refund orders failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<GetCalculateModel>> getCalculate({
    required String cartId,
    required double lat,
    required double long,
    required DeliveryTypeEnum type,
    String? coupon,
  }) async {
    final data = {
      'cart_id': cartId,
      'address': {'latitude': lat, 'longitude': long},
      // Backend kwarg is coupon_code (order.get_calculate); the old 'coupon'
      // key was silently dropped server-side.
      if (coupon != null) 'coupon_code': coupon,
      // get_calculate only adds the delivery fee when delivery_type is
      // exactly "Delivery"; send the checkout's actual choice.
      'delivery_type':
          type == DeliveryTypeEnum.delivery ? 'Delivery' : 'Pickup',
    };
    try {
      final response = await _gateway.tenant('api.order.get_calculate', data);
      return ApiResult.success(
        data: GetCalculateModel.fromJson(_payloadMap(response)),
      );
    } catch (e) {
      debugPrint('==> get calculate failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<CouponResponse>> checkCoupon({
    required String coupon,
    required String shopId,
  }) async {
    // Backend kwargs are code/shop_id (coupon.check_coupon); the old
    // coupon/shop keys never matched the function signature.
    final data = {'code': coupon, 'shop_id': shopId};
    try {
      final response = await _gateway.tenant('api.coupon.check_coupon', data);
      return ApiResult.success(data: CouponResponse.fromJson(response));
    } catch (e) {
      debugPrint('==> check coupon failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<OrderPaginateResponse>> getCompletedOrders(int page) {
    return getOrders(page: page, status: 'delivered');
  }

  /// Every non-terminal status, as one comma-separated list_orders
  /// filter. Before 1.26.0 the active fetch sent 'accepted' alone, so the
  /// home glance card and the active tab never showed an order that was
  /// processing, ready or on its way.
  static const String activeStatuses = 'accepted,processing,ready,on_a_way';

  @override
  Future<ApiResult<OrderPaginateResponse>> getActiveOrders(int page) {
    return getOrders(page: page, status: activeStatuses);
  }

  @override
  Future<ApiResult<OrderPaginateResponse>> getHistoryOrders(int page) {
    return getOrders(page: page);
  }

  @override
  Future<ApiResult<void>> createRepeatingOrder({
    required String orderId,
    required String startDate,
    required String cronPattern,
    String? endDate,
  }) async {
    try {
      await _gateway.tenant(
        'api.repeating_order.create_repeating_order',
        {
          'original_order': orderId,
          'start_date': startDate,
          'cron_pattern': cronPattern,
          if (endDate != null) 'end_date': endDate,
        },
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<void>> deleteRepeatingOrder({
    required String repeatingOrderId,
  }) async {
    try {
      await _gateway.tenant(
        'api.repeating_order.delete_repeating_order',
        {'repeating_order_id': repeatingOrderId},
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<String>> tipProcess({
    required String orderId,
    required double tip,
  }) async {
    try {
      // Backend kwarg is tip_amount (payment.tip_process, pay/wallet module).
      final response = await _gateway.tenant(
        'api.payment.tip_process',
        {'order_id': orderId, 'tip_amount': tip},
      );
      return ApiResult.success(data: response['redirect_url']);
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<CashbackModel>> checkCashback({
    required String shopId,
    required double amount,
  }) async {
    try {
      final response = await _gateway.tenant(
        'api.shop.check_cashback',
        {'shop_id': shopId, 'amount': amount},
      );
      // shop.check_cashback returns a bare {cashback_amount}; the model
      // reads `price`.
      final Map<String, dynamic> body = _payloadMap(response);
      return ApiResult.success(
        data: CashbackModel.fromJson({
          ...body,
          'price': body['price'] ?? body['cashback_amount'],
        }),
      );
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<LocalLocation>> getDriverLocation(String deliveryId) async {
    try {
      // Backend kwarg is driver_id (delivery.get_driver_location, zones
      // module); the old order_id key never matched the function signature.
      final response = await _gateway.tenant(
        'api.delivery.get_driver_location',
        {'driver_id': deliveryId},
      );
      return ApiResult.success(
        data: LocalLocation.fromJson(_payloadMap(response)),
      );
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}
