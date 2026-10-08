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

import 'package:orders_sdk/src/manager/domain/interface/shop_loads.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/load_data.dart';
import 'shop_loads_state.dart';

/// The shop's loads list, fetched one `load_status` at a time through
/// `get_shop_loads(status)` — the backend's own filter — and kept in the
/// bucket that status names.
///
/// `get_shop_loads` returns the whole set for a status in one answer (it
/// takes no paging arguments), so there is no View-more lane here and the
/// counts are the lists' own lengths.
class ShopLoadsNotifier extends StateNotifier<ShopLoadsState> {
  final ShopLoadsRepositoryFacade _repository;

  ShopLoadsNotifier(this._repository) : super(const ShopLoadsState());

  /// Both buckets, each through its own filtered call.
  Future<void> fetchLoads() async {
    state = state.copyWith(isLoading: true);
    await Future.wait([
      _fetchStatus(kLoadStatusOpen),
      _fetchStatus(kLoadStatusClosed),
    ]);
    if (!mounted) return;
    state = state.copyWith(isLoading: false);
  }

  Future<void> _fetchStatus(String status) async {
    final response = await _repository.getShopLoads(status: status);
    if (!mounted) return;
    response.when(
      success: (loads) {
        // The status the call asked for is the status the bucket holds:
        // a backend that answered wider than it was asked cannot spill
        // closed loads into the open tab.
        final List<LoadData> rows = filterLoadsByStatus(loads, status);
        state = status == kLoadStatusOpen
            ? state.copyWith(openLoads: rows)
            : state.copyWith(closedLoads: rows);
      },
      failure: (error, statusCode) {},
    );
  }

  /// Closes [loadOrder] and charges the driver the variance. Answers the
  /// closed load so the caller can show what was charged, or null when
  /// the backend refused — nothing is moved between the buckets on a
  /// refusal.
  Future<LoadData?> closeLoad(String loadOrder) async {
    if (state.closingId != null) return null;
    state = state.copyWith(closingId: loadOrder);
    final response = await _repository.closeLoad(loadOrder: loadOrder);
    LoadData? closed;
    response.when(
      success: (load) => closed = load,
      failure: (error, statusCode) {},
    );
    if (!mounted) return closed;
    final LoadData? settled = closed;
    state = state.copyWith(
      closingId: null,
      openLoads: settled == null
          ? state.openLoads
          : [
              for (final load in state.openLoads)
                if (load.id != settled.id) load,
            ],
      closedLoads: settled == null
          ? state.closedLoads
          : [settled, ...state.closedLoads.where((l) => l.id != settled.id)],
    );
    return settled;
  }

  /// Puts a just-issued load at the top of the open bucket, so the list
  /// the issue screen returns to already carries it.
  void addIssuedLoad(LoadData load) {
    state = state.copyWith(
      openLoads: [load, ...state.openLoads.where((l) => l.id != load.id)],
    );
  }
}
