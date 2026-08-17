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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:delivery_sdk/src/driver/di/driver_delivery_di.dart';
import 'package:delivery_sdk/src/driver/domain/interface/parcel.dart';
import 'package:base_sdk/src/models/data/parcel_order.dart';
import 'package:base_sdk/src/models/response/parcel_paginate_response.dart';

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';

class CourierParcelRepository implements CourierParcelRepositoryFacade {
  /// Prefix-free cmd base for the universal platform gateway: delivery's
  /// `manifest.json` whitelisted-method keys
  /// (`{app_name}.api.driver_parcel.*`) with the app segment dropped.
  static const _cmd = 'api.driver_parcel';

  static const _gateway = PlatformGateway();

  @override
  Future<ApiResult<List<ParcelOrder>>> getActiveOrders(int page) async {
    final data = {
      'currency_id': LocalStorage.getSelectedCurrency()!.id,
      'lang': LocalStorage.getLanguage()?.locale ?? 'en',
      'page': page,
      "statuses[1]": "accepted",
      "statuses[2]": "ready",
      "statuses[3]": "on_a_way",
      "perPage": 10,
      "delivery_type": "delivery"
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/dashboard/deliveryman/parcel-orders/paginate',
        queryParameters: data,
      );
      return ApiResult.success(
        data: ParcelPaginateResponse.fromJson(response.data).data ?? [],
      );
    } catch (e) {
      debugPrint('==> get active orders failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<List<ParcelOrder>>> getAvailableOrders(int page) async {
    final data = {
      'currency_id': LocalStorage.getSelectedCurrency()!.id,
      'lang': LocalStorage.getLanguage()?.locale ?? 'en',
      'page': page,
      "status": "ready",
      "empty-deliveryman": 1,
      "perPage": 10,
      "delivery_type": "delivery"
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/dashboard/deliveryman/parcel-orders/paginate',
        queryParameters: data,
      );
      return ApiResult.success(
        data: ParcelPaginateResponse.fromJson(response.data).data ?? [],
      );
    } catch (e) {
      debugPrint('==> get canceled orders failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<ParcelOrder>> showParcel(int id) async {
    final data = {
      'currency_id': LocalStorage.getSelectedCurrency()?.id,
      'lang': LocalStorage.getLanguage()?.locale ?? 'en',
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/dashboard/deliveryman/parcel-orders$id',
        queryParameters: data,
      );
      return ApiResult.success(
        data: ParcelOrder.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get single order failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<List<ParcelOrder>>> getHistoryOrders(int page,
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
        '/api/v1/dashboard/deliveryman/parcel-orders/paginate',
        queryParameters: data,
      );
      return ApiResult.success(
        data: ParcelPaginateResponse.fromJson(response.data).data ?? [],
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
      // `/api/v1/dashboard/deliveryman/parcel-orders/{id}/current` path
      // to the whitelisted Frappe def, through the universal platform
      // gateway (delivery's manifest registers the
      // `{app_name}.api.driver_parcel.set_current_parcel_order` alias).
      // The caller ignores the response body.
      await _gateway.tenant(
        '$_cmd.set_current_parcel_order',
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
  Future<ApiResult<dynamic>> updateParcel(int? parcelId, String? status) async {
    try {
      // Rewired from the dead legacy
      // `/api/v1/dashboard/deliveryman/parcel-orders/{id}/status/update`
      // path to the working Frappe convention, now through the universal
      // platform gateway. The backend normalizes the legacy lowercase
      // statuses ("delivered", "on_a_way", "canceled").
      await _gateway.tenant(
        '$_cmd.update_driver_parcel_order_status',
        {"order_id": parcelId, "status": status},
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
  Future<ApiResult<dynamic>> confirmParcelCodCollection(
      int? parcelId, num amountReceived) async {
    try {
      // FrappeResponseInterceptor already unwraps the top-level `message`
      // key, so the gateway answer is the endpoint's payload itself.
      final response = await _gateway.tenant(
        '$_cmd.confirm_parcel_cod_collection',
        {"parcel_id": parcelId, "amount_received": amountReceived},
      );
      return ApiResult.success(data: response);
    } catch (e) {
      debugPrint('===> error confirm parcel cod collection $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<void>> addReviewParcel(
    num orderId, {
    required double rating,
    required String comment,
  }) async {
    final data = {
      'order_id': orderId,
      'rating': rating,
      if (comment.isNotEmpty) 'comment': comment,
    };
    try {
      // Repointed from the dead legacy
      // `/api/v1/dashboard/deliveryman/parcel-orders/{id}/review` path
      // to the whitelisted Frappe def, through the universal platform
      // gateway (delivery's manifest registers the
      // `{app_name}.api.driver_parcel.add_parcel_order_review` alias);
      // signature: add_parcel_order_review(order_id, rating, comment).
      await _gateway.tenant(
        '$_cmd.add_parcel_order_review',
        data,
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
  Future<ApiResult<ParcelOrder>> setParcel(String parcelId) async {
    try {
      // Repointed from the dead legacy
      // `/api/v1/dashboard/deliveryman/parcel-order/{id}/attach/me` path
      // to the whitelisted Frappe def, through the universal platform
      // gateway (delivery's manifest registers the
      // `{app_name}.api.driver_parcel.attach_parcel_order_to_me` alias).
      // The def answers {"status": bool, "data": <raw doc dict>}; the
      // raw doc dict is not legacy ParcelOrder-shaped and the only
      // caller (home_notifier.setParcel) ignores the model, so an empty
      // ParcelOrder is returned on success instead of force-parsing it.
      final body = await _gateway.tenant(
        '$_cmd.attach_parcel_order_to_me',
        {'order_id': parcelId},
      );
      if (body is! Map || body['status'] != true) {
        // Parcel gone or already attached to another courier.
        return ApiResult.failure(
          error: 'Parcel order is no longer available',
          statusCode: 0,
        );
      }
      return ApiResult.success(
        data: ParcelOrder(),
      );
    } catch (e) {
      debugPrint('===> error statistics settings $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }
}
