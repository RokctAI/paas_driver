import 'package:flutter/material.dart';
import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/domain/interface/orders.dart';
import 'package:base_sdk/src/models/data/order_active_model.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/services/enums.dart';

class OrdersRepository implements OrdersRepositoryFacade {
  @override
  Future<ApiResult<OrderActiveModel>> createOrder(
    OrderBodyData orderBody,
  ) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.post(
        '/api/method/paas.api.order.order.create_order',
        data: orderBody.toJson(),
      );
      return ApiResult.success(data: OrderActiveModel.fromJson(response.data));
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
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
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/method/paas.api.order.order.list_orders',
        queryParameters: data,
      );
      return ApiResult.success(
        data: OrderPaginateResponse.fromJson(response.data),
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
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/method/paas.api.order.order.get_order_details',
        queryParameters: {'order_id': orderId},
      );
      return ApiResult.success(data: OrderActiveModel.fromJson(response.data));
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
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/method/paas.api.order.order.add_order_review',
        data: data,
      );
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
        '/api/method/paas.api.payment.payment.initiate_${name.toLowerCase()}_payment',
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
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/method/paas.api.order.order.cancel_order',
        data: {'order_id': orderId},
      );
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
        '/api/method/paas.api.user.user.create_order_refund',
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
        '/api/method/paas.api.user.user.get_user_order_refunds',
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
      if (coupon != null) 'coupon': coupon,
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.post(
        '/api/method/paas.api.order.order.get_calculate',
        data: data,
      );
      return ApiResult.success(
        data: GetCalculateModel.fromJson(response.data["message"]),
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
    final data = {'coupon': coupon, 'shop': shopId};
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.post(
        '/api/method/paas.api.coupon.coupon.check_coupon',
        data: data,
      );
      return ApiResult.success(data: CouponResponse.fromJson(response.data));
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
      final client = dioHttp.client(requireAuth: true);
      final response = await client.post(
        '/api/method/paas.api.tip_process',
        data: {'order_id': orderId, 'tip': tip},
      );
      return ApiResult.success(data: response.data['redirect_url']);
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
      final client = dioHttp.client(requireAuth: true);
      final response = await client.post(
        '/api/method/paas.api.check_cashback',
        data: {'shop_id': shopId, 'amount': amount},
      );
      return ApiResult.success(
        data: CashbackModel.fromJson(response.data['message']),
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
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/method/paas.api.get_driver_location',
        queryParameters: {'order_id': deliveryId},
      );
      return ApiResult.success(
        data: LocalLocation.fromJson(response.data['message']),
      );
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}
