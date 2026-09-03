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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:base_sdk/src/domain/interface/parcel.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/models/response/parcel_paginate_response.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';

class ParcelRepository implements ParcelRepositoryFacade {
  /// Universal platform gateway (fleet rule 2026-08-15): parcel cmds are the
  /// zones delivery module's `manifest.json` whitelisted-method keys with the
  /// app segment dropped (`api.parcel.*`), plus wallet's `api.payment.*`
  /// for the hosted-checkout and transaction calls.
  static const _gateway = PlatformGateway();

  /// The parcel-flavoured hosted-checkout initiators the wallet frappe half
  /// whitelists (`api.payment.initiate_{flutterwave|paypal|paystack}_parcel_payment`).
  static const Set<String> hostedCheckoutProviders = {
    'flutterwave',
    'paypal',
    'paystack',
  };

  @override
  Future<ApiResult<void>> addReview(
    String orderId, {
    required double rating,
    required String comment,
  }) async {
    // Backend kwargs are parcel_id/rating/review (parcel.add_parcel_review);
    // the old body sent no parcel id and used 'comment'.
    final data = {
      'parcel_id': orderId,
      'rating': rating,
      if (comment != "") 'review': comment,
    };
    try {
      await _gateway.tenant('api.parcel.add_parcel_review', data);
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> add parcel review failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<ParcelTypeResponse>> getTypes() async {
    final data = {'lang': LocalStorage.getLanguage()?.locale};
    try {
      final response = await _gateway.call(
        'api.parcel.get_types',
        payload: data,
        requireAuth: false,
      );
      return ApiResult.success(
        data: ParcelTypeResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> get parcel type failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<ParcelCalculateResponse>> getCalculate({
    required String typeId,
    required LocationModel from,
    required LocationModel to,
  }) async {
    // Backend kwargs are type_id/address_from/address_to maps
    // (parcel.calculate_price); the old bracket-style keys never matched.
    final data = {
      'lang': LocalStorage.getLanguage()?.locale,
      'type_id': typeId,
      'currency_id': LocalStorage.getSelectedCurrency()?.id,
      'address_from': {'latitude': from.latitude, 'longitude': from.longitude},
      'address_to': {'latitude': to.latitude, 'longitude': to.longitude},
    };
    try {
      final response = await _gateway.call(
        'api.parcel.calculate_price',
        payload: data,
        requireAuth: false,
      );
      return ApiResult.success(
        data: ParcelCalculateResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> get parcel type failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult> orderParcel({
    required String typeId,
    required LocationModel from,
    required String fromTitle,
    required LocationModel to,
    required String toTitle,
    required String time,
    required String note,
    required String phoneFrom,
    required String phoneTo,
    required String usernameTo,
    required String floorTo,
    required String floorFrom,
    required String houseFrom,
    required String houseTo,
    required String value,
    required String comment,
    required String instruction,
    required bool notify,
    required String usernameFrom,
    num? codAmount,
  }) async {
    final data = {
      'lang': LocalStorage.getLanguage()?.locale,
      'type_id': typeId,
      'currency_id': LocalStorage.getSelectedCurrency()?.id,
      "address_from": {
        "address": fromTitle,
        "latitude": from.latitude,
        "longitude": from.longitude,
        if (floorFrom.isNotEmpty) 'stage': floorFrom,
        if (houseFrom.isNotEmpty) 'house': houseFrom,
      },
      "address_to": {
        "address": toTitle,
        "latitude": to.latitude,
        "longitude": to.longitude,
        if (floorTo.isNotEmpty) 'stage': floorTo,
        if (houseTo.isNotEmpty) 'house': houseTo,
      },
      'rate': LocalStorage.getSelectedCurrency()?.rate,
      'delivery_date': DateFormat("yyyy-MM-dd").format(DateTime.now()),
      'delivery_time': time,
      if (comment.isNotEmpty) 'note': comment,
      if (instruction.isNotEmpty) 'instruction': instruction,
      if (note.isNotEmpty) 'description': note,
      if (value.isNotEmpty) 'qr_value': value,
      'phone_from': phoneFrom,
      'phone_to': phoneTo,
      'notify': notify ? 1 : 0,
      'username_from': usernameFrom,
      'username_to': usernameTo,
      // Optional COD: sender asks the driver to collect this cash amount
      // from the recipient. Omitted entirely when the sender didn't opt in.
      if (codAmount != null && codAmount > 0) 'cod_amount': codAmount,
    };
    try {
      final res = await _gateway.tenant(
        'api.parcel.create_parcel_order',
        {'order_data': data},
      );
      return ApiResult.success(data: res["data"]["id"]);
    } catch (e) {
      debugPrint('==> get parcel order failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<ParcelPaginateResponse>> getActiveParcel(int page) async {
    final data = {
      if (LocalStorage.getSelectedCurrency() != null)
        'currency_id': LocalStorage.getSelectedCurrency()?.id,
      'lang': LocalStorage.getLanguage()?.locale,
      'page': page,
      'statuses[0]': "new",
      "statuses[1]": "accepted",
      "statuses[2]": "ready",
      "statuses[3]": "on_a_way",
      "order_statuses": true,
      "perPage": 10,
    };
    try {
      // Status filtering logic as implemented in previous session
      if (data['statuses[0]'] != null) {
        data['status'] = [
          data['statuses[0]'],
          data['statuses[1]'],
          data['statuses[2]'],
          data['statuses[3]'],
        ];
        data.removeWhere((key, value) => key.startsWith('statuses'));
      }
      final response = await _gateway.tenant('api.parcel.get_parcel_orders', data);
      return ApiResult.success(
        data: ParcelPaginateResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> get open parcel failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<ParcelPaginateResponse>> getHistoryParcel(int page) async {
    final data = {
      if (LocalStorage.getSelectedCurrency() != null)
        'currency_id': LocalStorage.getSelectedCurrency()?.id,
      'lang': LocalStorage.getLanguage()?.locale,
      'statuses[0]': "delivered",
      "statuses[1]": "canceled",
      "order_statuses": true,
      "perPage": 10,
      "page": page,
    };
    try {
      if (data['statuses[0]'] != null) {
        data['status'] = [data['statuses[0]'], data['statuses[1]']];
        data.removeWhere((key, value) => key.startsWith('statuses'));
      }
      final response = await _gateway.tenant('api.parcel.get_parcel_orders', data);
      return ApiResult.success(
        data: ParcelPaginateResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> get canceled parcel failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<ParcelOrder>> getSingleParcel(String orderId) async {
    final data = {
      if (LocalStorage.getSelectedCurrency() != null)
        'currency_id': LocalStorage.getSelectedCurrency()?.id,
      'lang': LocalStorage.getLanguage()?.locale,
    };
    try {
      final response = await _gateway.tenant(
        'api.parcel.get_user_parcel_order',
        {'name': orderId},
      );
      return ApiResult.success(
        data: ParcelOrder.fromJson(response["data"]),
      );
    } catch (e) {
      debugPrint('==> get single parcel failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<String>> process(String orderId, String name) async {
    final String provider = name.toLowerCase();
    if (!hostedCheckoutProviders.contains(provider)) {
      return ApiResult.failure(
        error: 'No hosted checkout is available for "$name" on this backend',
        statusCode: 400,
      );
    }
    try {
      // wallet's payment.initiate_<provider>_parcel_payment(order_id) — the
      // kwarg is named order_id even for a Parcel Order docname; it answers
      // the same {redirect_url} envelope as the order variant.
      final response = await _gateway.tenant(
        'api.payment.initiate_${provider}_parcel_payment',
        {'order_id': orderId},
      );
      return ApiResult.success(data: response['redirect_url']);
    } catch (e) {
      debugPrint('==> parcel payment process failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<TransactionsResponse>> createTransaction({
    required String orderId,
    required String paymentId,
  }) async {
    // TODO(fix-wave 2026-09-02): wallet's create_order_transaction resolves
    // order_id against the Order doctype only (payment.py:1667), so a Parcel
    // Order docname is refused server-side until the method learns parcels.
    // Routed through the gateway anyway so the refusal is a real server
    // answer rather than a router 404 (fixplan M15).
    try {
      final response = await _gateway.tenant(
        'api.payment.create_order_transaction',
        {'order_id': orderId, 'payment_sys_id': paymentId},
      );
      return ApiResult.success(
        data: TransactionsResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> create transaction failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}
