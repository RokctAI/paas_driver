import 'package:flutter/material.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:products_sdk/src/common/domain/interface/seller_catalog.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_category_data.dart';
import 'package:products_sdk/src/manager/application/foods/create/details/category/add_food_categories_state.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

/// Port of `paas_manager`'s `AddFoodCategoriesNotifier` — the category picker
/// (main + sub) on the create-product flow. Fetch failures surface as
/// `state.error` instead of an in-notifier snackbar (stage 2 convention).
class AddFoodCategoriesNotifier extends StateNotifier<AddFoodCategoriesState> {
  AddFoodCategoriesNotifier(this._repository)
      : super(
          AddFoodCategoriesState(categoryController: TextEditingController()),
        );

  final SellerCatalogRepositoryFacade _repository;

  int _page = 0;

  Future<void> updateCategories({RefreshController? controller}) async {
    if (controller == null) {
      _page = 0;
    }
    final response = await _repository.getCategories(page: ++_page);
    response.when(
      success: (data) {
        final List<SellerCategoryData> categories =
            List.from(state.categories);
        final List<SellerCategoryData> newCategories = data.data ?? [];
        for (final category in newCategories) {
          final bool contains =
              categories.any((old) => old.id == category.id);
          if (!contains) {
            categories.insert(0, category);
          }
        }
        state = state.copyWith(categories: categories, activeIndex: 0);
        if (categories.isNotEmpty) {
          state.categoryController?.text =
              state.categories[0].translation?.title ?? '';
        }
        controller?.loadComplete();
        if (data.data?.isEmpty ?? true) {
          controller?.loadNoData();
        }
      },
      failure: (failure, status) {
        debugPrint('====> fetch categories fail $failure');
        _page--;
        state = state.copyWith(error: failure);
      },
    );
  }

  Future<void> updateCategoriesSub({RefreshController? controller}) async {
    if (controller == null) {
      _page = 0;
    }
    final response = await _repository.getCategoriesSub(page: ++_page);
    response.when(
      success: (data) {
        final List<SellerCategoryData> categories =
            List.from(state.categoriesSub);
        final List<SellerCategoryData> newCategories = data.data ?? [];
        for (final category in newCategories) {
          final bool contains =
              categories.any((old) => old.id == category.id);
          if (!contains) {
            categories.insert(0, category);
          }
        }
        state = state.copyWith(categoriesSub: categories, activeIndex: 0);
        if (categories.isNotEmpty) {
          state.categorySubController?.text =
              state.categoriesSub[0].translation?.title ?? '';
        }
        controller?.loadComplete();
        if (data.data?.isEmpty ?? true) {
          controller?.loadNoData();
        }
      },
      failure: (failure, status) {
        debugPrint('====> fetch sub categories fail $failure');
        _page--;
        state = state.copyWith(error: failure);
      },
    );
  }

  void setActiveIndex(int index) {
    if (state.activeIndex == index) {
      return;
    }
    state = state.copyWith(activeIndex: index);
    state.categoryController?.text =
        state.categories[index].translation?.title ?? '';
  }

  void setActiveIndexSub(int index) {
    if (state.activeSubIndex == index) {
      return;
    }
    state = state.copyWith(
      activeSubIndex: index,
      categorySubController: TextEditingController(
        text: state.categoriesSub[index].translation?.title ?? '',
      ),
    );
  }

  void setCategories(List<SellerCategoryData> categories) {
    if (state.categories.isEmpty) {
      _page = 0;
      state = state.copyWith(categories: categories, activeIndex: 0);
      if (categories.isNotEmpty) {
        state.categoryController?.text =
            state.categories[0].translation?.title ?? '';
      }
    }
  }

  Future<void> deleteCategories(SellerCategoryData category) async {
    final res = await _repository.deleteCategory(id: category.id);
    res.when(
      success: (success) {
        final List<SellerCategoryData> list = List.from(state.categories)
          ..remove(category);
        state = state.copyWith(categories: list, activeIndex: 0);
      },
      failure: (failure, s) {
        debugPrint('delete categories fail: $failure');
      },
    );
  }

  void setCategoriesSub(List<SellerCategoryData> categories) {
    if (state.categoriesSub.isEmpty) {
      _page = 0;
      state = state.copyWith(categoriesSub: categories, activeSubIndex: 0);
      if (categories.isNotEmpty) {
        state.categorySubController?.text =
            state.categoriesSub[0].translation?.title ?? '';
      }
    }
  }
}
