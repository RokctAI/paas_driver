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

import 'package:products_sdk/src/manager/application/catalog/catalog_state.dart';

/// Selection driver for the catalog plane flow — deliberately dumb: the
/// product itself is always re-resolved from `foodsProvider`'s list by id, so
/// list refreshes keep an open detail pane current (the kitchen notifier's
/// selection idiom).
class CatalogNotifier extends StateNotifier<CatalogState> {
  CatalogNotifier() : super(const CatalogState());

  void select(String? id) {
    state = id == null
        ? state.copyWith(clearSelection: true)
        : state.copyWith(selectedId: id);
  }

  /// Wide-screen auto-select (the kitchen queue's idiom) so the approved
  /// 35a never shows a bare last plane while products exist.
  void autoSelect(String id) {
    if (state.selectedId != null) return;
    state = state.copyWith(selectedId: id);
  }

  void openQuickAdjust() => state = state.copyWith(quickAdjustOpen: true);

  void closeQuickAdjust() => state = state.copyWith(quickAdjustOpen: false);
}
