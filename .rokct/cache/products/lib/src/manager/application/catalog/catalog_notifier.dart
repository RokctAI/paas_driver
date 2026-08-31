// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
