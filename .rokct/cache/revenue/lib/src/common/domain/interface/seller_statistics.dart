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
}
