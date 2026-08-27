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
