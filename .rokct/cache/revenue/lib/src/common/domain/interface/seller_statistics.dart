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

/// Narrow contract for the seller/manager revenue + statistics surface.
///
/// Declared here rather than in `base_sdk`: ADR-005 lets a consumer own the
/// interface it needs, and nothing outside `revenue_sdk` consumes seller
/// statistics. Keeping it local avoids widening `base_sdk`, which every app in
/// the family inherits.
///
/// This is also the contract the Frappe side must satisfy — see
/// `docs/frappe-endpoint-contract.md` for the endpoint list, current coverage
/// and the gaps the backend workstream still needs to close.
library;

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/profit_report_response.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/statistics_order_response.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/statistics_response.dart';

abstract class SellerStatisticsRepositoryFacade {
  /// Order-report statistics for a date window, including the earnings series
  /// the income page charts.
  Future<ApiResult<StatisticsResponse>> getStatistics({
    required DateTime startTime,
    required DateTime endTime,
  });

  /// Paginated per-order rows for the same window.
  Future<ApiResult<StatisticsOrderResponse>> getStatisticsOrder({
    DateTime? startTime,
    DateTime? endTime,
    int? page,
    int? perPage,
  });

  /// Profitability aggregates for an inclusive [from]..[to] date window —
  /// `api.seller_report.get_seller_profit_report` (the section-36 dashboard's
  /// one new endpoint). Deltas against a previous period come from calling
  /// this again with the shifted window.
  Future<ApiResult<ProfitReportResponse>> getProfitReport({
    required DateTime from,
    required DateTime to,
  });
}
