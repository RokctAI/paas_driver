// Copyright (c) 2026 RokctAI
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

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:delivery_sdk/src/driver/di/driver_delivery_di.dart';
import 'package:delivery_sdk/src/driver/domain/interface/orders.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/order_detail.dart';

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/order_paginate_response.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';

class CourierOrdersRepository implements CourierOrdersRepositoryFacade {
  /// Prefix-free cmd base for the universal platform gateway: map's
  /// `manifest.json` whitelisted-method keys
  /// (`{app_name}.api.driver_order.*`) with the app segment dropped.
  static const _cmd = 'api.driver_order';

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
    final data = {
      'currency_id': LocalStorage.getSelectedCurrency()!.id,
      'lang': LocalStorage.getLanguage()?.locale ?? 'en',
      'page': page,
      "status": "ready",
      "empty-deliveryman": 1,
      "perPage": 10,
      "delivery_type": "delivery",
      "address": {
        "latitude": LocalStorage.getAddressSelected()?.latitude ??
            AppConstants.demoLatitude,
        "longitude": LocalStorage.getAddressSelected()?.longitude ??
            AppConstants.demoLongitude
      }
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/dashboard/deliveryman/orders/paginate',
        queryParameters: data,
      );
      return ApiResult.success(
        data: OrderPaginateResponse.fromJson(response.data).data ?? [],
      );
    } catch (e) {
      debugPrint('==> get canceled orders failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<OrderDetailModel>> showOrders(int id) async {
    final data = {
      'currency_id': LocalStorage.getSelectedCurrency()?.id,
      'lang': LocalStorage.getLanguage()?.locale ?? 'en',
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/dashboard/deliveryman/orders/$id',
        queryParameters: data,
      );
      return ApiResult.success(
        data: OrderDetailModel.fromJson(response.data),
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
    final data = {
      'currency_id': LocalStorage.getSelectedCurrency()!.id,
      'lang': LocalStorage.getLanguage()?.locale ?? 'en',
      'page': page,
      "status": "delivered",
      "perPage": 10,
      if (start != null)
        "delivery_date_from": DateFormat("yyyy-MM-dd").format(start),
      if (end != null) "delivery_date_to": DateFormat("yyyy-MM-dd").format(end),
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/dashboard/deliveryman/orders/paginate',
        queryParameters: data,
      );
      return ApiResult.success(
        data: OrderPaginateResponse.fromJson(response.data).data ?? [],
      );
    } catch (e) {
      debugPrint('==> get delivered orders failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<dynamic>> setCurrentOrder(int? orderId) async {
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
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/dashboard/deliveryman/orders/paginate?perPage=1&lang=en&current=1',
      );
      return ApiResult.success(
        data: OrderPaginateResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('===> error current order settings $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<dynamic>> updateOrder(int? orderId, String? status) async {
    try {
      // Rewired from the dead legacy
      // `/api/v1/dashboard/deliveryman/order/{id}/status/update` path to the
      // working Frappe convention, now through the universal platform
      // gateway. The backend normalizes the legacy lowercase statuses
      // ("delivered", "on_a_way", "canceled") itself.
      await _gateway.tenant(
        '$_cmd.update_driver_order_status',
        {"order_id": orderId, "status": status},
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
      int? orderId, num amountReceived) async {
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
  Future<ApiResult<dynamic>> convertCodToCredit(int? orderId) async {
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
  Future<ApiResult<dynamic>> uploadImage(int? orderId, String? image) async {
    try {
      // Repointed from the dead legacy
      // `/api/v1/dashboard/deliveryman/orders/{id}/image` path (pre-fork
      // code even hardcoded https://api.foodyman.org here) to the
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
    num orderId, {
    required double rating,
    required String comment,
  }) async {
    final data = {
      'rating': rating,
      if (comment.isNotEmpty) 'comment': comment,
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/v1/dashboard/deliveryman/orders/$orderId/review',
        data: data,
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
  Future<ApiResult<void>> cancelOrder(int orderId, String note) async {
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
