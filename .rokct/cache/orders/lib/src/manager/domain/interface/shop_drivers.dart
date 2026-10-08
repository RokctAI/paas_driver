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
import 'package:orders_sdk/src/manager/infrastructure/models/data/shop_driver.dart';

/// The shop's OWN-DRIVER roster: which drivers this shop keeps.
///
/// Ray's ruling, the shop half: a shop may hire its own drivers instead of
/// drawing from the platform pool for every load. The roster is what
/// records that, and the load side reads it — a shop with a roster can only
/// issue loads to the drivers on it.
///
/// The endpoints belong to the ZONES app's delivery module
/// (`api.shop_drivers.*`), not to orders, but the roster is a SHOP screen
/// and the shop's screens are this slice's, so the facade lives here beside
/// [ShopLoadsRepositoryFacade] and is implemented by orders_sdk itself over
/// the universal gateway. Nothing is faked: a tenant composed without zones
/// has no such methods and every call fails visibly through
/// [ApiResult.failure].
///
/// All three calls are scoped to the CALLER'S shop on the backend. Nothing
/// here names a shop, and nothing here can reach another one's roster.
abstract class ShopDriversRepositoryFacade {
  /// This shop's own drivers.
  Future<ApiResult<List<ShopDriver>>> listShopDrivers();

  /// Put a driver on this shop's roster. [deliveryman] is the driver's User
  /// id, the handle the platform driver list and `create_load` both use.
  Future<ApiResult<bool>> addShopDriver({required String deliveryman});

  /// Take a driver off this shop's roster.
  Future<ApiResult<bool>> removeShopDriver({required String deliveryman});
}
