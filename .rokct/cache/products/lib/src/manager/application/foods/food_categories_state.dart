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

import 'package:products_sdk/src/common/infrastructure/models/data/seller_category_data.dart';

class FoodCategoriesState {
  const FoodCategoriesState({
    this.isLoading = false,
    this.categories = const [],
    this.activeIndex = 0,
    this.error,
  });

  final bool isLoading;
  final List<SellerCategoryData> categories;
  final int activeIndex;

  /// Set on a failed fetch. The app raised a snackbar from inside the notifier,
  /// passing a `BuildContext` into the application layer; the failure is
  /// surfaced as state instead and the page decides how to show it.
  final String? error;

  FoodCategoriesState copyWith({
    bool? isLoading,
    List<SellerCategoryData>? categories,
    int? activeIndex,
    String? error,
  }) =>
      FoodCategoriesState(
        isLoading: isLoading ?? this.isLoading,
        categories: categories ?? this.categories,
        activeIndex: activeIndex ?? this.activeIndex,
        error: error,
      );
}
