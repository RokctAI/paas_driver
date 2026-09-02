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

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:revenue_sdk/src/common/domain/interface/courier_statistics.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/courier_statistics_income_response.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/courier_statistics_order_response.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/courier_statistics_response.dart';

/// Demo-only [CourierStatisticsRepositoryFacade]
/// (`--dart-define=IS_DEMO=true`): serves a small fictional week of courier
/// earnings offline so the driver /income screen is never a zeroed shell in
/// demo builds — the same `AppConstants.isDemo` split delivery_sdk's
/// `DriverDeliveryDependencies` applies to every courier facade
/// (DemoLmsRepository precedent). Registered in place of
/// `CourierStatisticsRepository` by `DriverRevenueDependencies`; zero
/// behavior change when IS_DEMO is off. Never used in production; nothing
/// leaves the device.
class DemoCourierStatisticsRepository
    implements CourierStatisticsRepositoryFacade {
  /// Seven days of per-day earnings ending today, so every tab window
  /// (today / weekly / monthly) has points inside it.
  static List<CourierChart> _chartDays() {
    const dailyTotals = <num>[420, 385, 510, 465, 540, 610, 480];
    final today = DateTime.now();
    return [
      for (var i = 0; i < dailyTotals.length; i++)
        CourierChart(
          time: DateTime(today.year, today.month, today.day)
              .subtract(Duration(days: dailyTotals.length - 1 - i)),
          totalPrice: dailyTotals[i],
        ),
    ];
  }

  @override
  Future<ApiResult<CourierStatisticsResponse>> getCourierStatistics() async =>
      ApiResult.success(
        data: CourierStatisticsResponse(
          status: true,
          data: CourierStatisticsData(
            progressOrdersCount: 2,
            deliveredOrdersCount: 128,
            cancelOrdersCount: 3,
            newOrdersCount: 1,
            acceptedOrdersCount: 2,
            readyOrdersCount: 1,
            onAWayOrdersCount: 1,
            ordersCount: 133,
            totalPrice: 480,
          ),
        ),
      );

  @override
  Future<ApiResult<CourierStatisticsIncomeResponse>> getStatistics({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final chart = _chartDays();
    final total = chart.fold<num>(0, (sum, c) => sum + (c.totalPrice ?? 0));
    return ApiResult.success(
      data: CourierStatisticsIncomeResponse(
        data: CourierStatisticsModel(
          lastOrderTotalPrice: 180,
          lastOrderIncome: 45,
          totalPrice: total,
          fmTotalPrice: total,
          totalCount: 133,
          totalNewCount: 1,
          totalReadyCount: 1,
          totalOnAWayCount: 1,
          totalAcceptedCount: 2,
          totalCanceledCount: 3,
          totalDeliveredCount: 128,
          totalTodayCount: 6,
          chart: chart,
        ),
      ),
    );
  }

  @override
  Future<ApiResult<CourierStatisticsOrderResponse>> getStatisticsOrder({
    DateTime? startTime,
    DateTime? endTime,
    int? page,
  }) async {
    final now = DateTime.now();
    return ApiResult.success(
      data: CourierStatisticsOrderResponse(
        status: true,
        data: (page ?? 1) > 1
            ? const []
            : [
                CourierStatisticsOrder(
                  createdAt: now.subtract(const Duration(hours: 1)),
                  totalPrice: 180,
                  fmTotalPrice: 180,
                ),
                CourierStatisticsOrder(
                  createdAt: now.subtract(const Duration(hours: 3)),
                  totalPrice: 145,
                  fmTotalPrice: 145,
                ),
                CourierStatisticsOrder(
                  createdAt: now.subtract(const Duration(hours: 5)),
                  totalPrice: 155,
                  fmTotalPrice: 155,
                ),
              ],
      ),
    );
  }
}
