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
