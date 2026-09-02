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

import 'package:flutter/material.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_category_data.dart';

/// Plain immutable state (no freezed) — same reason as the stage 2 states.
///
/// The `TextEditingController`s ride along in state as they did in the app;
/// the picker modal binds its field to them directly.
class AddFoodCategoriesState {
  const AddFoodCategoriesState({
    this.categories = const [],
    this.categoriesSub = const [],
    this.activeIndex = 1,
    this.activeSubIndex = 1,
    this.categoryController,
    this.categorySubController,
    this.error,
  });

  final List<SellerCategoryData> categories;
  final List<SellerCategoryData> categoriesSub;
  final int activeIndex;
  final int activeSubIndex;
  final TextEditingController? categoryController;
  final TextEditingController? categorySubController;

  /// Set on a failed fetch; the page decides how to show it.
  final String? error;

  AddFoodCategoriesState copyWith({
    List<SellerCategoryData>? categories,
    List<SellerCategoryData>? categoriesSub,
    int? activeIndex,
    int? activeSubIndex,
    TextEditingController? categoryController,
    TextEditingController? categorySubController,
    String? error,
  }) =>
      AddFoodCategoriesState(
        categories: categories ?? this.categories,
        categoriesSub: categoriesSub ?? this.categoriesSub,
        activeIndex: activeIndex ?? this.activeIndex,
        activeSubIndex: activeSubIndex ?? this.activeSubIndex,
        categoryController: categoryController ?? this.categoryController,
        categorySubController:
            categorySubController ?? this.categorySubController,
        error: error,
      );
}
