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
