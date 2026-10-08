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
import 'package:orders_sdk/src/manager/infrastructure/models/data/load_data.dart';

/// The SHOP side of consignment loads (commerce#135's `load.py`).
///
/// Owned and implemented by orders_sdk itself
/// ([ShopLoadsRepository]) — like [SellerOrdersRepositoryFacade] and
/// unlike the ADR-005 seams, this is orders' own data, so no host adapter
/// stands between the screens and the endpoints.
///
/// The driver's half of the same module (`get_my_load`, `create_load_sale`,
/// `return_load`) is the driver app's, not the manager's, and is
/// deliberately absent here. `close_load` is on BOTH sides — the backend
/// lets either the driver or the shop close a load — and is declared here
/// because the shop must be able to close one without the driver.
abstract class ShopLoadsRepositoryFacade {
  /// Every consignment load this shop has issued, newest first.
  /// [status] narrows to `open` or `closed`; omitted, both come back.
  Future<ApiResult<List<LoadData>>> getShopLoads({String? status});

  /// The drivers this shop can issue a load to.
  Future<ApiResult<List<LoadDeliveryman>>> listShopDeliverymen();

  /// Issue a load: [items] are `{stock, quantity}` rows off the shop's own
  /// shelf, and issuing is what takes them off it. [deliveryman] is the
  /// driver's User id (a Deliveryman Profile docname resolves too).
  Future<ApiResult<LoadData>> createLoad({
    required String deliveryman,
    required List<LoadIssueLine> items,
  });

  /// Close a load and charge the driver the variance. Idempotent on the
  /// backend: a load already closed comes back untouched with
  /// `alreadyClosed` set and no money moved.
  Future<ApiResult<LoadData>> closeLoad({required String loadOrder});
}

/// One `{stock, quantity}` row on the way out — the only shape the
/// backend addresses quantities by, on every call in the module.
class LoadIssueLine {
  final String stockId;
  final num quantity;

  const LoadIssueLine({required this.stockId, required this.quantity});

  Map<String, dynamic> toJson() => {'stock': stockId, 'quantity': quantity};
}
