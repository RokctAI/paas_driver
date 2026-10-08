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

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:orders_sdk/src/manager/infrastructure/models/data/load_data.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/shop_driver.dart';

part 'shop_drivers_state.freezed.dart';

/// The shop's own-driver roster screen: who is on it, who could be added,
/// and which row is on the wire.
@freezed
abstract class ShopDriversState with _$ShopDriversState {
  const factory ShopDriversState({
    @Default(false) bool isLoading,
    @Default(false) bool hasFailed,
    @Default([]) List<ShopDriver> drivers,

    /// The drivers the shop could add, from the load module's platform
    /// driver list. Empty until the add flow asks for it.
    @Default(false) bool isLoadingCandidates,
    @Default([]) List<LoadDeliveryman> candidates,

    /// Typed into the add flow's search field.
    @Default('') String query,

    /// The driver id an add or a remove is in flight for; one at a time, so
    /// the row that is moving is the one that shows it.
    String? pendingId,
  }) = _ShopDriversState;

  const ShopDriversState._();

  /// The roster rows the shop actually keeps, active first and each in the
  /// order the backend listed them.
  List<ShopDriver> get activeDrivers =>
      drivers.where((driver) => driver.active).toList();

  /// The add flow's list: every platform driver who is not already on the
  /// roster, narrowed by [query]. Matching is on the name AND the id,
  /// because a shop that knows a driver only by his login should still be
  /// able to find him.
  List<LoadDeliveryman> get addableCandidates {
    final Set<String> already = drivers.map((driver) => driver.id).toSet();
    final String needle = query.trim().toLowerCase();
    return candidates
        .where((driver) => !already.contains(driver.id))
        .where(
          (driver) =>
              needle.isEmpty ||
              driver.name.toLowerCase().contains(needle) ||
              driver.id.toLowerCase().contains(needle),
        )
        .toList();
  }
}
