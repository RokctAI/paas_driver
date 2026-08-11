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
