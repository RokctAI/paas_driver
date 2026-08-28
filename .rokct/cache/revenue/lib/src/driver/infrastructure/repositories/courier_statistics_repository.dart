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

import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

import 'package:revenue_sdk/src/common/domain/interface/courier_statistics.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/courier_statistics_income_response.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/courier_statistics_order_response.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/courier_statistics_response.dart';

/// Courier earnings/stats, ported from paas_driver's UserRepositoryImpl.
///
/// Repointed from the dead legacy `/api/v1/dashboard/...` surface (recorded
/// with its payloads in `paas_driver/docs/fork-endpoint-handoff.md`) onto the
/// whitelisted Frappe defs, through base_sdk's universal platform gateway.
/// The server speaks the legacy-key envelopes these response models already
/// parse, so no model changed shape.
class CourierStatisticsRepository implements CourierStatisticsRepositoryFacade {
  /// Prefix-free cmd base for the universal platform gateway: delivery's
  /// `manifest.json` whitelisted-method keys
  /// (`{app_name}.api.delivery_man.*`) with the app segment dropped.
  static const _deliveryCmd = 'api.delivery_man';

  /// Same convention for map's `manifest.json` whitelisted-method keys
  /// (`{app_name}.api.driver_order.*`).
  static const _driverOrderCmd = 'api.driver_order';

  static const _gateway = PlatformGateway();

  /// Formats a DateTime as the bare `yyyy-MM-dd` the report endpoints expect.
  ///
  /// The original sliced the string at its first space; kept as an explicit
  /// helper so the intent is legible, but the behaviour is identical.
  String _day(DateTime d) => d.toIso8601String().split('T').first;

  /// Normalizes a gateway answer to the string-keyed map the response
  /// factories take; anything unexpected parses as empty rather than
  /// throwing.
  Map<String, dynamic> _asMap(dynamic response) =>
      response is Map ? Map<String, dynamic>.from(response) : <String, dynamic>{};

  @override
  Future<ApiResult<CourierStatisticsResponse>> getCourierStatistics() async {
    try {
      // Repointed from the dead legacy
      // `/api/v1/dashboard/deliveryman/statistics/count` path to the
      // whitelisted Frappe def (delivery manifest key
      // `api.delivery_man.get_deliveryman_statistics`) through the
      // universal platform gateway. The def answers the legacy-key
      // envelope this model parses: {"data": {progress_orders_count,
      // delivered_orders_count, ..., last_delivered_fee}}.
      final response = await _gateway.tenant(
        '$_deliveryCmd.get_deliveryman_statistics',
      );
      return ApiResult.success(
        data: CourierStatisticsResponse.fromJson(_asMap(response)),
      );
    } catch (e) {
      debugPrint('===> get courier statistics error $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<CourierStatisticsIncomeResponse>> getStatistics({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      // Repointed from the dead legacy
      // `/api/v1/dashboard/deliveryman/order/report` path to the
      // whitelisted Frappe def (delivery manifest key
      // `api.delivery_man.get_deliveryman_order_report`) through the
      // universal platform gateway. The pre-fork app sent date_from built
      // from endTime and date_to from startTime (noted here as "looks
      // inverted" and carried over blind); the Frappe contract is an
      // explicit chronological [from_date, to_date] window, so the args
      // are mapped straight at this repoint. The def answers the
      // legacy-key envelope this model parses: {"data": {total_price,
      // total_delivered_count, total_count, chart: [{time,
      // total_price}]}}.
      final data = {
        'from_date': _day(startTime),
        'to_date': _day(endTime),
      };
      final response = await _gateway.tenant(
        '$_deliveryCmd.get_deliveryman_order_report',
        data,
      );
      return ApiResult.success(
        data: CourierStatisticsIncomeResponse.fromJson(_asMap(response)),
      );
    } catch (e) {
      debugPrint('===> get statistics error $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<CourierStatisticsOrderResponse>> getStatisticsOrder({
    DateTime? startTime,
    DateTime? endTime,
    int? page,
  }) async {
    try {
      // Repointed from the dead legacy
      // `/api/v1/dashboard/seller/orders/report/paginate` path — confirmed
      // shared-monolith residue (a `seller/` path called from the courier
      // app) — to the deliveryman-scoped Frappe paginate def the driver
      // order surface already uses (map manifest key
      // `api.driver_order.get_driver_orders_paginate`), through the
      // universal platform gateway, filtered to delivered orders. The
      // backend normalizes the legacy lowercase "delivered", bounds the
      // creation date with the optional date_from/date_to kwargs (either
      // bound alone works), and its serializer emits the Laravel-era
      // `created_at` alias plus `total_price` this model reads.
      // `fm_total_price` has no Frappe concept and stays null —
      // render-optional on the client.
      const perPage = 10;
      final data = {
        'limit_start': ((page ?? 1) - 1) * perPage,
        'limit_page_length': perPage,
        'statuses': jsonEncode(["delivered"]),
        if (startTime != null) 'date_from': _day(startTime),
        if (endTime != null) 'date_to': _day(endTime),
      };
      final response = await _gateway.tenant(
        '$_driverOrderCmd.get_driver_orders_paginate',
        data,
      );
      return ApiResult.success(
        data: CourierStatisticsOrderResponse.fromJson(_asMap(response)),
      );
    } catch (e) {
      debugPrint('===> get statistics order error $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}
