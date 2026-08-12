import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../edit/edit_product_modal.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:products_sdk/src/manager/application/foods/edit/details/edit_food_details_provider.dart';
import 'package:products_sdk/src/manager/application/foods/edit/details/category/edit_food_categories_provider.dart';
import 'package:products_sdk/src/manager/application/foods/edit/details/units/edit_food_units_provider.dart';
import 'package:products_sdk/src/manager/application/foods/food_categories_provider.dart';
import 'package:products_sdk/src/manager/application/foods/foods_provider.dart';
import 'package:base_sdk/src/presentation/components/loading/tab_bar_loading.dart';
import 'package:base_sdk/src/presentation/components/categories_tab_bar.dart';
import 'package:${package}/presentation/components/foods/products_body.dart';

/// Kitchen-picker seeding moved out of the tap handler: the legacy page seeded
/// `editFoodKitchensProvider` here, but kitchen_sdk's replacement
/// (`kitchenPickerProvider`) is autoDispose and would drop state seeded before
/// the modal builds — EditFoodDetailsBody seeds it in its own initState from
/// the product it already has.
class FoodsBody extends StatelessWidget {
  final RefreshController categoryController;
  final RefreshController productController;

  const FoodsBody({
    super.key,
    required this.categoryController,
    required this.productController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        24.verticalSpace,
        Consumer(
          builder: (context, ref, child) {
            final categoriesState = ref.watch(foodCategoriesProvider);
            final categoriesEvent = ref.read(foodCategoriesProvider.notifier);
            final productsEvent = ref.read(foodsProvider.notifier);
            return categoriesState.isLoading
                ? const TabBarLoading()
                : SizedBox(
                    height: 36.h,
                    child: CategoriesTabBar(
                      categories: categoriesState.categories,
                      activeIndex: categoriesState.activeIndex,
                      refreshController: categoryController,
                      onChangeTab: (index) {
                        categoriesEvent.setActiveIndex(index);
                        if (index != categoriesState.activeIndex) {
                          productsEvent.fetchCategoryProducts(
                            categoryId: index == 1
                                ? null
                                : categoriesState.categories[index - 2].id,
                            refreshController: productController,
                          );
                        }
                      },
                      onLoading: () => categoriesEvent.fetchCategories(
                        refreshController: categoryController,
                      ),
                    ),
                  );
          },
        ),
        8.verticalSpace,
        Expanded(
          child: Consumer(
            builder: (context, ref, child) {
              final productsState = ref.watch(foodsProvider);
              final productsEvent = ref.read(foodsProvider.notifier);
              return ProductsBody(
                itemSpacing: 10,
                isLoading: productsState.isLoading,
                products: productsState.foods,
                refreshController: productController,
                scrollPhysics: const NeverScrollableScrollPhysics(),
                onRefreshing: () => productsEvent.refreshProducts(
                  refreshController: productController,
                ),
                onLoading: () => productsEvent.fetchMoreProducts(
                  refreshController: productController,
                ),
                onProductTap: (index) {
                  ref
                      .read(editFoodDetailsProvider.notifier)
                      .setFoodDetails(productsState.foods[index]);
                  ref
                      .read(editFoodUnitsProvider.notifier)
                      .setFoodUnit(productsState.foods[index].unit);
                  ref
                      .read(editFoodCategoriesProvider.notifier)
                      .setFoodCategory(productsState.foods[index].category);
                  AppHelpers.showCustomModalBottomSheet(
                    paddingTop: 60,
                    context: context,
                    modal: EditProductModal(
                      controller: ScrollController(),
                      product: productsState.foods[index],
                    ),
                    isDarkMode: false,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
