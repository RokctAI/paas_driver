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
import 'package:kitchen_sdk/src/manager/infrastructure/models/response/kitchen_orders_response.dart';
import 'package:kitchen_sdk/src/manager/presentation/kitchen/kitchen_status.dart';

/// The manager Kitchen screen's data seam. Owned and implemented by
/// kitchen_sdk itself ([KitchenOrdersRepository]) — order data, so no host
/// adapter is involved (orders_sdk's SellerOrdersRepositoryFacade
/// precedent).
///
/// Every id is a Frappe hash docname string — never a numeric id.
abstract class KitchenOrdersRepositoryFacade {
  /// The kitchen queue (shop-scoped). [status] narrows to one chip;
  /// null is the All filter (every kitchen-relevant status). [search]
  /// narrows by order-number substring. [page] is 1-based.
  Future<ApiResult<KitchenOrdersResponse>> getKitchenOrders({
    KitchenStatus? status,
    String? search,
    int? page,
  });

  /// Order-level status transition, riding the EXISTING seller order
  /// status endpoint (`api.seller_order.update_seller_order_status`) —
  /// [wireStatus] is the legacy lowercase wire value; 'cooking',
  /// 'on_a_way' and 'delivered' are legal here beyond [KitchenStatus]
  /// because the hand-over routing leaves the kitchen vocabulary.
  Future<ApiResult<void>> updateOrderStatus({
    required String orderId,
    required String wireStatus,
  });

  /// One dish line's prep state
  /// (`api.cook.update_kitchen_dish_status`).
  Future<ApiResult<void>> updateDishStatus({
    required String orderId,
    required String dishId,
    required DishStatus status,
  });
}
