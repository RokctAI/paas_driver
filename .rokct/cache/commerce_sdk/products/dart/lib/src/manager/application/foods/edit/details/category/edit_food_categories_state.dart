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
class EditFoodCategoriesState {
  const EditFoodCategoriesState({
    this.isLoading = false,
    this.categories = const [],
    this.activeIndex = 0,
    this.categoriesController,
    this.foodCategory,
  });

  final bool isLoading;
  final List<SellerCategoryData> categories;
  final int activeIndex;
  final TextEditingController? categoriesController;
  final SellerCategoryData? foodCategory;

  EditFoodCategoriesState copyWith({
    bool? isLoading,
    List<SellerCategoryData>? categories,
    int? activeIndex,
    TextEditingController? categoriesController,
    SellerCategoryData? foodCategory,
  }) =>
      EditFoodCategoriesState(
        isLoading: isLoading ?? this.isLoading,
        categories: categories ?? this.categories,
        activeIndex: activeIndex ?? this.activeIndex,
        categoriesController: categoriesController ?? this.categoriesController,
        foodCategory: foodCategory ?? this.foodCategory,
      );
}
