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

part 'shop_loads_state.freezed.dart';

/// The shop's consignment loads, one bucket per `load_status` — the same
/// shape the order board keeps its per-status queues in, so switching the
/// list's tab never costs a round trip and both counts are always real.
@freezed
abstract class ShopLoadsState with _$ShopLoadsState {
  const factory ShopLoadsState({
    @Default(false) bool isLoading,
    @Default([]) List<LoadData> openLoads,
    @Default([]) List<LoadData> closedLoads,

    /// The load whose Close call is in flight; the row and the detail's
    /// action both go quiet while it is set.
    String? closingId,
  }) = _ShopLoadsState;

  const ShopLoadsState._();
}
