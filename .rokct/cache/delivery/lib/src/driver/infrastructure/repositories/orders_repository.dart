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

// compliance-ignore-file: flutter-http-timeout
// The package:dio import below is only for its request/response types.
// The actual client comes from base_sdk's dioHttp (HttpService), which sets
// connectTimeout and receiveTimeout (30s) centrally on its BaseOptions; no
// unconfigured HTTP client is created in this file.

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:delivery_sdk/src/driver/domain/interface/orders.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/order_detail.dart';

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/order_paginate_response.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/driver_day_report.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

class CourierOrdersRepository implements CourierOrdersRepositoryFacade {
  /// Prefix-free cmd base for the universal platform gateway: map's
  /// `manifest.json` whitelisted-method keys
  /// (`{app_name}.api.driver_order.*`) with the app segment dropped.
  static const _cmd = 'api.driver_order';

  /// Same convention for delivery's `manifest.json` whitelisted-method
  /// keys (`{app_name}.api.delivery_man.*`).
  static const _deliveryCmd = 'api.delivery_man';

  static const _gateway = PlatformGateway();

  @override
  Future<ApiResult<OrderPaginateResponse>> getActiveOrders(int page) async {
    // Rewired from the dead legacy `/api/v1/dashboard/deliveryman/orders/
    // paginate` path to the working Frappe endpoint, now through the
    // universal platform gateway. The backend normalizes the legacy
    // lowercase statuses and returns {"data": [...], "meta": {"total": n}}
    // shaped for OrderDetailData (FrappeResponseInterceptor already
    // unwraps the top-level `message` key, so the gateway answer is that
    // envelope itself).
    const perPage = 10;
    final data = {
      'limit_start': (page - 1) * perPage,
      'limit_page_length': perPage,
      'statuses': jsonEncode(["accepted", "ready", "on_a_way"]),
    };
    try {
      final response =
          await _gateway.tenant('$_cmd.get_driver_orders_paginate', data);
      return ApiResult.success(
        data: OrderPaginateResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> get active orders failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<List<OrderDetailData>>> getAvailableOrders(int page) async {
    // Repointed from the dead legacy `/api/v1/dashboard/deliveryman/
    // orders/paginate?empty-deliveryman=1` path to the whitelisted
    // Frappe def (delivery manifest key
    // `api.delivery_man.get_available_orders`) through the universal
    // platform gateway. The server owns the "no deliveryman yet +
    // ready-for-pickup" filter, so the legacy currency/lang/address
    // query knobs are dropped; the envelope mirrors the paginate
    // contract ({"data": [...], "meta": {"total": n}}).
    const perPage = 10;
    final data = {
      'limit_start': (page - 1) * perPage,
      'limit_page_length': perPage,
    };
    try {
      final response =
          await _gateway.tenant('$_deliveryCmd.get_available_orders', data);
      return ApiResult.success(
        data: OrderPaginateResponse.fromJson(response).data ?? [],
      );
    } catch (e) {
      debugPrint('==> get available orders failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<DriverDayReport>> getDayReport({
    required DateTime from,
    required DateTime to,
  }) async {
    // The endpoint is date-bounded and has been whitelisted since before
    // this screen existed (delivery manifest key
    // `api.delivery_man.get_deliveryman_order_report`); driver home
    // simply never called it. Bounds are sent as plain yyyy-MM-dd, which
    // is what `creation_range_filter` parses.
    final formatter = DateFormat('yyyy-MM-dd');
    try {
      final response = await _gateway.tenant(
        '$_deliveryCmd.get_deliveryman_order_report',
        {
          'from_date': formatter.format(from),
          'to_date': formatter.format(to),
        },
      );
      return ApiResult.success(data: DriverDayReport.fromJson(response));
    } catch (e) {
      debugPrint('==> get deliveryman day report failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<DriverWorkStatus>> getWorkStatus() async {
    try {
      final response = await _gateway.tenant(
        '$_deliveryCmd.get_deliveryman_work_status',
        const {},
      );
      return ApiResult.success(data: DriverWorkStatus.fromJson(response));
    } catch (e) {
      debugPrint('==> get deliveryman work status failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<OrderDetailModel>> showOrders(String id) async {
    try {
      // Repointed from the dead legacy
      // `/api/v1/dashboard/deliveryman/orders/{id}` path to the
      // whitelisted deliveryman-scoped detail def (delivery manifest key
      // `api.delivery_man.get_deliveryman_order_details`; the generic
      // order-detail endpoint rejects non-owners) through the universal
      // platform gateway. The def answers {"data": <serializer row>} —
      // exactly the envelope OrderDetailModel.fromJson reads.
      final response = await _gateway.tenant(
        '$_deliveryCmd.get_deliveryman_order_details',
        {'order_id': id},
      );
      return ApiResult.success(
        data: OrderDetailModel.fromJson(
          response is Map ? Map<String, dynamic>.from(response) : {},
        ),
      );
    } catch (e) {
      debugPrint('==> get single order failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<List<OrderDetailData>>> getHistoryOrders(int page,
      {DateTime? start, DateTime? end}) async {
    // Repointed from the dead legacy `/api/v1/dashboard/deliveryman/
    // orders/paginate?status=delivered` path to the same working Frappe
    // paginate def getActiveOrders already uses, through the universal
    // platform gateway. The backend normalizes the legacy lowercase
    // "delivered" and bounds the creation date with the optional
    // date_from/date_to kwargs (either bound alone works).
    const perPage = 10;
    final data = {
      'limit_start': (page - 1) * perPage,
      'limit_page_length': perPage,
      'statuses': jsonEncode(["delivered"]),
      if (start != null) 'date_from': DateFormat("yyyy-MM-dd").format(start),
      if (end != null) 'date_to': DateFormat("yyyy-MM-dd").format(end),
    };
    try {
      final response =
          await _gateway.tenant('$_cmd.get_driver_orders_paginate', data);
      return ApiResult.success(
        data: OrderPaginateResponse.fromJson(response).data ?? [],
      );
    } catch (e) {
      debugPrint('==> get delivered orders failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<dynamic>> setCurrentOrder(String? orderId) async {
    try {
      // Repointed from the dead legacy
      // `/api/v1/dashboard/deliveryman/orders/{id}/current` path to the
      // whitelisted Frappe def, through the universal platform gateway
      // (map's manifest registers the
      // `{app_name}.api.driver_order.set_current_order` alias). The
      // caller ignores the response body.
      await _gateway.tenant(
        '$_cmd.set_current_order',
        {'order_id': orderId},
      );
      return const ApiResult.success(
        data: null,
      );
    } catch (e) {
      debugPrint('==> get delivered orders failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<OrderPaginateResponse>> fetchCurrentOrder() async {
    try {
      // Repointed from the dead legacy `/api/v1/dashboard/deliveryman/
      // orders/paginate?current=1` path to the working Frappe paginate
      // def, through the universal platform gateway, asking for the
      // single newest in-progress order. (map's `fetch_current_order`
      // def exists but is not whitelisted in its manifest and answers a
      // raw doc dict, not this OrderPaginateResponse envelope — reusing
      // the paginate def avoids both problems.)
      final response = await _gateway.tenant(
        '$_cmd.get_driver_orders_paginate',
        {
          'limit_start': 0,
          'limit_page_length': 1,
          'statuses': jsonEncode(["accepted", "on_a_way"]),
        },
      );
      return ApiResult.success(
        data: OrderPaginateResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('===> error current order settings $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<dynamic>> updateOrder(String? orderId, String? status,
      {bool recipientAgeVerified = false}) async {
    try {
      // Rewired from the dead legacy
      // `/api/v1/dashboard/deliveryman/order/{id}/status/update` path to the
      // working Frappe convention, now through the universal platform
      // gateway. The backend normalizes the legacy lowercase statuses
      // ("delivered", "on_a_way", "canceled") itself.
      await _gateway.tenant(
        '$_cmd.update_driver_order_status',
        {
          "order_id": orderId,
          "status": status,
          // Additive: sent only when the courier explicitly confirmed the
          // recipient's ID on an 18+ order. Only this yes/no confirmation
          // travels - no ID image or document data is ever captured.
          if (recipientAgeVerified) "recipient_age_verified": true,
        },
      );
      return const ApiResult.success(
        data: null,
      );
    } catch (e) {
      debugPrint('===> error statistics settings $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<dynamic>> confirmCodCollection(
      String? orderId, num amountReceived) async {
    try {
      // FrappeResponseInterceptor already unwraps the top-level `message`
      // key, so the gateway answer is the endpoint's payload itself.
      final response = await _gateway.tenant(
        '$_cmd.confirm_cod_collection',
        {"order_id": orderId, "amount_received": amountReceived},
      );
      return ApiResult.success(data: response);
    } catch (e) {
      debugPrint('===> error confirm cod collection $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<dynamic>> convertCodToCredit(String? orderId) async {
    try {
      final response = await _gateway.tenant(
        '$_cmd.convert_cod_to_credit',
        {"order_id": orderId},
      );
      return ApiResult.success(data: response);
    } catch (e) {
      debugPrint('===> error convert cod to credit $e');
      return ApiResult.failure(
          error: _frappeThrowMessage(e) ?? AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  /// Frappe's `frappe.throw` responses carry the human-readable sentence
  /// inside `_server_messages` (a JSON-encoded list of JSON strings), not
  /// a top-level `message` key, so the generic error handler falls through
  /// to the raw exception text. Extract it so the driver sees the
  /// backend's own message (e.g. "This shop does not offer credit.").
  /// Returns null when the response is not a recognizable frappe throw.
  String? _frappeThrowMessage(dynamic e) {
    if (e is! DioException) return null;
    final data = e.response?.data;
    if (data is! Map) return null;
    final serverMessages = data['_server_messages'];
    if (serverMessages is! String || serverMessages.isEmpty) return null;
    try {
      final decoded = jsonDecode(serverMessages);
      if (decoded is! List || decoded.isEmpty) return null;
      final first = decoded.first;
      final entry = first is String ? jsonDecode(first) : first;
      final message = entry is Map ? entry['message'] : entry;
      if (message is! String) return null;
      // Frappe may wrap the text in markup; strip any tags.
      final clean = message.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      return clean.isEmpty ? null : clean;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ApiResult<dynamic>> uploadImage(
      String? orderId, String? image) async {
    try {
      // Repointed from the dead legacy
      // `/api/v1/dashboard/deliveryman/orders/{id}/image` path (pre-fork
      // code even hardcoded the upstream vendor's API host here) to the
      // whitelisted Frappe def, through the universal platform gateway
      // (map's manifest registers the
      // `{app_name}.api.driver_order.upload_order_image` alias). Payload
      // key follows the def's signature:
      // upload_order_image(order_id, image_url).
      await _gateway.tenant(
        '$_cmd.upload_order_image',
        {"order_id": orderId, "image_url": image},
      );
      return const ApiResult.success(
        data: null,
      );
    } catch (e) {
      debugPrint('===> error statistics settings $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<void>> addReview(
    String orderId, {
    required double rating,
    required String comment,
  }) async {
    try {
      // Repointed from the dead legacy
      // `/api/v1/dashboard/deliveryman/orders/{id}/review` path to the
      // whitelisted deliveryman-scoped review def (delivery manifest key
      // `api.delivery_man.add_deliveryman_order_review`; the generic
      // review endpoint rejects non-owners) through the universal
      // platform gateway. The caller ignores the response body.
      await _gateway.tenant(
        '$_deliveryCmd.add_deliveryman_order_review',
        {
          'order_id': orderId,
          'rating': rating,
          if (comment.isNotEmpty) 'comment': comment,
        },
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> add order review failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<OrderDetailModel>> setOrder(String orderId) async {
    try {
      // Repointed from the dead legacy
      // `/api/v1/dashboard/deliveryman/order/{id}/attach/me` path to the
      // whitelisted Frappe def, through the universal platform gateway
      // (map's manifest registers the
      // `{app_name}.api.driver_order.attach_order_to_me` alias). The def
      // answers {"status": bool, "data": <raw doc dict>}; the raw doc
      // dict is not OrderDetailData-shaped (shop/user are Link name
      // strings), and the only caller (home_notifier.setOrder) ignores
      // the model anyway, so an empty OrderDetailModel is returned on
      // success instead of force-parsing it.
      final body = await _gateway.tenant(
        '$_cmd.attach_order_to_me',
        {'order_id': orderId},
      );
      if (body is! Map || body['status'] != true) {
        // Order gone or already attached to another courier.
        return ApiResult.failure(
          error: 'Order is no longer available',
          statusCode: 0,
        );
      }
      return ApiResult.success(
        data: OrderDetailModel(),
      );
    } catch (e) {
      debugPrint('===> error statistics settings $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<void>> cancelOrder(String orderId, String note) async {
    try {
      // Repointed from the dead legacy
      // `/api/v1/dashboard/deliveryman/order/{id}/status/update` path to
      // the same registered Frappe method the sibling updateOrder already
      // uses, through the universal platform gateway; the backend
      // normalizes the legacy lowercase "canceled".
      // KNOWN GAP: update_driver_order_status accepts no `note` kwarg,
      // so the cancellation reason is not persisted server-side yet.
      await _gateway.tenant(
        '$_cmd.update_driver_order_status',
        {"order_id": orderId, "status": "canceled"},
      );
      return const ApiResult.success(
        data: null,
      );
    } catch (e) {
      debugPrint('==> post cancel order failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }
}
