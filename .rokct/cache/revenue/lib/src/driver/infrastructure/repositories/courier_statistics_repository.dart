import 'package:flutter/foundation.dart';

import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

import 'package:revenue_sdk/src/common/domain/interface/courier_statistics.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/courier_statistics_income_response.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/courier_statistics_order_response.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/courier_statistics_response.dart';

/// Courier earnings/stats, ported from paas_driver's UserRepositoryImpl.
///
/// Still targets the legacy `/api/v1` surface. Those paths are recorded with
/// their payloads in `paas_driver/docs/fork-endpoint-handoff.md` for the
/// Frappe workstream; nothing here is stubbed or faked to look successful.
class CourierStatisticsRepository implements CourierStatisticsRepositoryFacade {
  /// Formats a DateTime as the bare `yyyy-MM-dd` the report endpoints expect.
  ///
  /// The original sliced the string at its first space; kept as an explicit
  /// helper so the intent is legible, but the behaviour is identical.
  String _day(DateTime d) => d.toIso8601String().split('T').first;

  @override
  Future<ApiResult<CourierStatisticsResponse>> getCourierStatistics() async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/dashboard/deliveryman/statistics/count',
      );
      return ApiResult.success(
        data: CourierStatisticsResponse.fromJson(response.data),
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
      // NOTE: date_from is built from endTime and date_to from startTime.
      // That looks inverted, but it is what the pre-fork app sent and what the
      // current backend evidently accepts, so it is carried over unchanged
      // rather than "fixed" blind. Worth confirming against the Frappe
      // implementation before either side is treated as canonical.
      final data = {
        "date_from": _day(endTime),
        "date_to": _day(startTime),
        "type": "day",
      };
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/dashboard/deliveryman/order/report',
        queryParameters: data,
      );
      return ApiResult.success(
        data: CourierStatisticsIncomeResponse.fromJson(response.data),
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
      final data = {
        if (endTime != null) "date_from": _day(endTime),
        if (startTime != null) "date_to": _day(startTime),
        "page": page,
        "perPage": 10,
      };
      final client = dioHttp.client(requireAuth: true);
      // NOTE: a `seller/` path called from the courier app. Inherited from the
      // pre-fork code; flagged in the endpoint handoff doc as possible residue
      // from the shared-monolith era. Confirm it is intended before the Frappe
      // equivalent is written against it.
      final response = await client.get(
        '/api/v1/dashboard/seller/orders/report/paginate',
        queryParameters: data,
      );
      return ApiResult.success(
        data: CourierStatisticsOrderResponse.fromJson(response.data),
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
