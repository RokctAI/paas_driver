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

/// Narrow contract for the driver's consignment-load surface (van sales).
///
/// The endpoints behind it are commerce's `api.order.load.*` defs. This
/// SDK does NOT depend on a commerce SDK (ADR-005: an SDK's `lib/` imports
/// only base_sdk), so the calls ride base_sdk's universal platform gateway
/// by prefix-free dotted name, exactly as [DriverDepositRepositoryFacade]
/// calls wallet's `api.wallet.*`.
///
/// THE STOCK MODEL, which every screen on this seam must honour:
///
///  * the shop issues the load; the driver never creates one. There is no
///    "take stock" call here and there must not be one.
///  * [createLoadSale] is the sale at the door: CASH, born Delivered and
///    Paid server-side. With no customer named it is on the driver's own
///    account — which is why this version's customer field offers exactly
///    that and nothing else.
///  * the server owns the quantity ceiling. [createLoadSale] and
///    [returnLoad] validate `quantity <= remaining` server-side; the
///    steppers cap at the same figure so the driver meets the limit as a
///    limit rather than as a refusal.
///  * [closeLoad] is the one that COSTS MONEY: everything neither sold nor
///    returned is charged to the driver's wallet at the load's unit price.
///    It is idempotent, so a second tap after a lost answer is safe.
library;

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/driver_load.dart';

/// One line of a sale or a return: the stock row and how much of it.
class DriverLoadMovement {
  const DriverLoadMovement({required this.stockId, required this.quantity});

  final String stockId;
  final num quantity;

  /// The wire shape both write calls take: `items: [{stock, quantity}]`.
  Map<String, dynamic> toJson() => {'stock': stockId, 'quantity': quantity};
}

abstract class DriverLoadRepositoryFacade {
  /// Every load issued to the session driver, newest first as the server
  /// orders them. An empty list is the normal state for most drivers on
  /// most days.
  Future<ApiResult<List<DriverLoad>>> getMyLoad();

  /// The sale at the door. [customer] stays null for a walk-in on the
  /// driver's own account — the only case this version can send (see
  /// `load_sale_page.dart`).
  ///
  /// [poi] is the point of interest the sale was made AT, when the driver
  /// named one. Optional and staying optional: the round learns which
  /// corners buy from the ones he names, and a sale he names nothing for
  /// still settles. The key rides the wire only when it is set.
  Future<ApiResult<DriverLoadSale>> createLoadSale({
    required String loadOrder,
    required List<DriverLoadMovement> items,
    String? customer,
    String? note,
    String? poi,
  });

  /// Unsold stock handed back to the shop.
  Future<ApiResult<DriverLoad>> returnLoad({
    required String loadOrder,
    required List<DriverLoadMovement> items,
  });

  /// Closes the load and charges the variance to the driver's wallet at
  /// the load price. Idempotent server-side.
  Future<ApiResult<DriverLoad>> closeLoad({required String loadOrder});
}
