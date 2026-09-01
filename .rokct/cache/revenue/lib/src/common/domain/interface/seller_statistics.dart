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
