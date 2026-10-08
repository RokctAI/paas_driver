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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:base_sdk/src/handlers/api_result.dart';

import 'package:orders_sdk/src/manager/domain/interface/shop_drivers.dart';
import 'package:orders_sdk/src/manager/domain/interface/shop_loads.dart';
import 'shop_drivers_state.dart';

/// Drives the shop's own-driver roster: read it, add to it, remove from it.
///
/// Two repositories, because the roster and the pool it is filled from are
/// two different backend modules — the roster is zones'
/// ([ShopDriversRepositoryFacade]), the pool of platform drivers is the
/// load module's `list_shop_deliverymen`
/// ([ShopLoadsRepositoryFacade.listShopDeliverymen]), which is also what
/// the issue-a-load picker draws.
///
/// Every write is re-read rather than guessed at: a successful add or
/// remove refetches the roster, so what the screen shows is what the
/// backend stored and a refusal leaves the list exactly as it was.
class ShopDriversNotifier extends StateNotifier<ShopDriversState> {
  final ShopDriversRepositoryFacade _roster;
  final ShopLoadsRepositoryFacade _loads;

  ShopDriversNotifier(this._roster, this._loads)
    : super(const ShopDriversState());

  Future<void> fetchDrivers() async {
    state = state.copyWith(isLoading: true, hasFailed: false);
    final response = await _roster.listShopDrivers();
    if (!mounted) return;
    response.when(
      success: (drivers) =>
          state = state.copyWith(isLoading: false, drivers: drivers),
      failure: (error, statusCode) =>
          state = state.copyWith(isLoading: false, hasFailed: true),
    );
  }

  /// The drivers the shop could add. Note what the backend answers here:
  /// once a shop HAS a roster, `list_shop_deliverymen` narrows to that
  /// roster, so this list empties out and the add flow says so plainly
  /// instead of pretending there is more pool to draw from.
  Future<void> fetchCandidates() async {
    state = state.copyWith(isLoadingCandidates: true);
    final response = await _loads.listShopDeliverymen();
    if (!mounted) return;
    response.when(
      success: (drivers) => state = state.copyWith(
        isLoadingCandidates: false,
        candidates: drivers,
      ),
      failure: (error, statusCode) =>
          state = state.copyWith(isLoadingCandidates: false),
    );
  }

  void setQuery(String query) => state = state.copyWith(query: query);

  /// Adds a driver. Answers whether the backend took it, so the caller can
  /// say so; the roster is refetched on success and untouched on a refusal.
  Future<bool> addDriver(String deliveryman) => _write(
    deliveryman,
    () => _roster.addShopDriver(deliveryman: deliveryman),
  );

  Future<bool> removeDriver(String deliveryman) => _write(
    deliveryman,
    () => _roster.removeShopDriver(deliveryman: deliveryman),
  );

  Future<bool> _write(
    String deliveryman,
    Future<ApiResult<bool>> Function() call,
  ) async {
    if (state.pendingId != null) return false;
    state = state.copyWith(pendingId: deliveryman);
    final response = await call();
    bool stored = false;
    response.when(
      success: (_) => stored = true,
      failure: (error, statusCode) {},
    );
    if (!mounted) return stored;
    state = state.copyWith(pendingId: null);
    if (stored) await fetchDrivers();
    return stored;
  }
}
