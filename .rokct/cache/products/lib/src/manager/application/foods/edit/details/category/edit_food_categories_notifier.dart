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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_category_data.dart';
import 'package:products_sdk/src/manager/application/foods/edit/details/category/edit_food_categories_state.dart';

/// Port of `paas_manager`'s `EditFoodCategoriesNotifier` — the category picker
/// on the edit-product flow. Purely local state: the category list itself is
/// handed in by the page (fetched via `foodCategoriesProvider`).
class EditFoodCategoriesNotifier
    extends StateNotifier<EditFoodCategoriesState> {
  EditFoodCategoriesNotifier()
      : super(
          EditFoodCategoriesState(
            categoriesController: TextEditingController(),
          ),
        );

  void setCategories(List<SellerCategoryData> list) {
    final List<SellerCategoryData> categories = List.from(list);
    int? index;
    if (state.foodCategory != null) {
      for (int i = 0; i < categories.length; i++) {
        if (state.foodCategory?.id == categories[i].id) {
          index = i;
        }
      }
      if (index == null) {
        categories.insert(0, state.foodCategory!);
      }
    }
    state = state.copyWith(
      categories: categories,
      activeIndex: index ?? 0,
      foodCategory: categories.isEmpty ? null : categories[index ?? 0],
    );
    state.categoriesController?.text =
        state.foodCategory?.translation?.title ?? '';
  }

  void setFoodCategory(SellerCategoryData? category) {
    state = state.copyWith(foodCategory: category);
    state.categoriesController?.text = category?.translation?.title ?? '';
  }

  void setActiveIndex(int index) {
    if (state.activeIndex == index) {
      return;
    }
    final newCategory = state.categories[index];
    state = state.copyWith(activeIndex: index, foodCategory: newCategory);
    state.categoriesController?.text = newCategory.translation?.title ?? '';
  }
}
