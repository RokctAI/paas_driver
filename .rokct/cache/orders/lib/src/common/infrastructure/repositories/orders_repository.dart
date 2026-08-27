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

import 'package:flutter/material.dart';
import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/domain/interface/orders.dart';
import 'package:base_sdk/src/models/data/order_active_model.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/enums.dart';

class OrdersRepository implements OrdersRepositoryFacade {
  /// Universal platform gateway (fleet rule 2026-08-15): cmds mirror the
  /// owning modules' `manifest.json` whitelisted-method keys with the app
  /// segment dropped (`api.order.*`, `api.coupon.*`, `api.shop.*`,
  /// `api.payment.*`, `api.delivery.*`).
  static const _gateway = PlatformGateway();

  @override
  Future<ApiResult<OrderActiveModel>> createOrder(
    OrderBodyData orderBody,
  ) async {
    try {
      final response = await _gateway.tenant(
        'api.order.create_order',
        orderBody.toJson().cast<String, dynamic>(),
      );
      return ApiResult.success(data: OrderActiveModel.fromJson(response));
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
      return ApiResult.success(
        data: OrderPaginateResponse.fromJson(response),
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
      return ApiResult.success(data: OrderActiveModel.fromJson(response));
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
    try {
      final client = dioHttp.client(requireAuth: true);
      var res = await client.post(
        '/api/method/paas.api.payment.initiate_${name.toLowerCase()}_payment',
        data: {'order_id': orderBody.cartId},
      );
      return ApiResult.success(data: res.data["redirect_url"]);
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
      final data = {"order": orderId, "cause": title};
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/method/paas.api.user.create_order_refund',
        data: data,
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
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/method/paas.api.repeating_order.create_repeating_order',
        data: {
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
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/method/paas.api.repeating_order.pause_repeating_order',
        data: {'repeating_order_id': autoOrderId},
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
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/method/paas.api.repeating_order.resume_repeating_order',
        data: {'repeating_order_id': autoOrderId},
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
    final data = {'page': page};
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/method/paas.api.user.get_user_order_refunds',
        queryParameters: data,
      );
      return ApiResult.success(data: RefundOrdersModel.fromJson(response.data));
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
    };
    try {
      final response = await _gateway.tenant('api.order.get_calculate', data);
      return ApiResult.success(
        data: GetCalculateModel.fromJson(response["message"]),
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

  @override
  Future<ApiResult<OrderPaginateResponse>> getActiveOrders(int page) {
    return getOrders(page: page, status: 'accepted');
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
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/method/paas.api.repeating_order.create_repeating_order',
        data: {
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
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/method/paas.api.repeating_order.delete_repeating_order',
        data: {'repeating_order_id': repeatingOrderId},
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
      return ApiResult.success(
        data: CashbackModel.fromJson(response['message']),
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
        data: LocalLocation.fromJson(response['message']),
      );
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}
