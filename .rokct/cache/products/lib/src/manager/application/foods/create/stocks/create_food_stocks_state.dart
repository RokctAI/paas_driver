// Copyright (c) 2026 RokctAI
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

import 'package:products_sdk/src/common/infrastructure/models/data/seller_extras.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_extras_group.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_stock.dart';

/// Plain immutable state (no freezed) — same reason as the stage 2 states.
class CreateFoodStocksState {
  const CreateFoodStocksState({
    this.isLoading = false,
    this.isSaving = false,
    this.isFetchingGroups = false,
    this.groups = const [],
    this.stocks = const [],
    this.activeGroupExtras = const [],
    this.selectGroups = const {},
    this.error,
  });

  final bool isLoading;
  final bool isSaving;
  final bool isFetchingGroups;
  final List<SellerExtrasGroup> groups;
  final List<SellerStock> stocks;
  final List<SellerExtras> activeGroupExtras;

  /// Selected extra values keyed by group id (as string) — the cartesian
  /// product of the values becomes the stock variants.
  final Map<String, List<SellerExtras?>> selectGroups;

  /// Set on a failed fetch or save; the page decides how to show it.
  final String? error;

  CreateFoodStocksState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isFetchingGroups,
    List<SellerExtrasGroup>? groups,
    List<SellerStock>? stocks,
    List<SellerExtras>? activeGroupExtras,
    Map<String, List<SellerExtras?>>? selectGroups,
    String? error,
  }) =>
      CreateFoodStocksState(
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        isFetchingGroups: isFetchingGroups ?? this.isFetchingGroups,
        groups: groups ?? this.groups,
        stocks: stocks ?? this.stocks,
        activeGroupExtras: activeGroupExtras ?? this.activeGroupExtras,
        selectGroups: selectGroups ?? this.selectGroups,
        error: error,
      );
}
