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

/// Narrow contract for the courier/driver earnings + delivery-stats surface.
///
/// Deliberately separate from [SellerStatisticsRepositoryFacade] rather than a
/// shared "statistics" seam: a seller's numbers are shop revenue analytics, a
/// courier's are delivery counts and personal earnings. They answer different
/// questions from different endpoints, and the response shapes only look alike
/// because both are named "statistics".
///
/// This lives in `common/` alongside the models it returns, mirroring
/// [SellerStatisticsRepositoryFacade]: seams stay common. `common/` must hold
/// the whole seam (facade plus the response types its signature names) because
/// the composer's role-stripping deletes non-matching role folders from an
/// app's cache — a manager app's cache has `lib/src/driver/` removed, so
/// anything the barrel exports, including this contract driver hosts import
/// through it, has to survive that strip. Only the concrete
/// `CourierStatisticsRepository` is driver-only and stays in `driver/`.
///
/// This is also the contract the Frappe side must satisfy — the endpoints the
/// ported Dart currently targets are listed in
/// `paas_driver/docs/fork-endpoint-handoff.md`.
library;

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/courier_statistics_income_response.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/courier_statistics_order_response.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/courier_statistics_response.dart';

abstract class CourierStatisticsRepositoryFacade {
  /// Lifetime delivery counters for the signed-in courier — total delivered,
  /// cancelled, in progress. Drives the summary tiles, not the chart.
  Future<ApiResult<CourierStatisticsResponse>> getCourierStatistics();

  /// Earnings for a date window, including the per-day series the income page
  /// charts. Returns plain values; building a chart from them is the
  /// presentation layer's job, so this SDK stays chart-library-agnostic.
  Future<ApiResult<CourierStatisticsIncomeResponse>> getStatistics({
    required DateTime startTime,
    required DateTime endTime,
  });

  /// Paginated per-order rows for the same window.
  Future<ApiResult<CourierStatisticsOrderResponse>> getStatisticsOrder({
    DateTime? startTime,
    DateTime? endTime,
    int? page,
  });
}
