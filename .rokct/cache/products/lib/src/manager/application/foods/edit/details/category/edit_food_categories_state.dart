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
