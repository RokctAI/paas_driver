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

import 'package:kitchen_sdk/src/manager/infrastructure/models/data/kitchen_order_data.dart';
import 'package:kitchen_sdk/src/manager/presentation/kitchen/kitchen_status.dart';

/// `api.cook.get_kitchen_orders` answer:
/// `{"orders": [...], "counts": {"all": n, "accepted": n, ...}, "total": n}`
/// — counts feed the filter chips, total the active filter's paging.
class KitchenOrdersResponse {
  final List<KitchenOrderData> orders;
  final Map<KitchenFilter, int> counts;
  final int total;

  const KitchenOrdersResponse({
    this.orders = const [],
    this.counts = const {},
    this.total = 0,
  });

  factory KitchenOrdersResponse.fromJson(dynamic json) {
    // Defensive: a proxy/HTML error body parses as not-a-map.
    if (json is! Map) return const KitchenOrdersResponse();
    final rawCounts = json['counts'];
    final counts = <KitchenFilter, int>{};
    if (rawCounts is Map) {
      for (final filter in KitchenFilter.values) {
        final value = rawCounts[filter.labelKey];
        if (value != null) {
          counts[filter] = int.tryParse('$value') ?? 0;
        }
      }
    }
    return KitchenOrdersResponse(
      orders: [
        for (final row in (json['orders'] as List? ?? const []))
          if (row is Map<String, dynamic>) KitchenOrderData.fromJson(row),
      ],
      counts: counts,
      total: int.tryParse('${json['total'] ?? 0}') ?? 0,
    );
  }
}
