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

// ISSUE A LOAD — /load/issue.
//
// The PRODUCT PICKER here is the create-order flow's picker, not a new
// one: the same `orderProductsProvider` / `productCategoriesProvider`
// pair behind the same search field, the same category chip bar and the
// same `ProductsBody` rows the walk-in till picks off. It lives in this
// installed shell because those rows are host components; the body
// (`IssueLoadBody`) keeps the draft, the quantities and the one
// `create_load` call, so the arithmetic is package code with tests.
//
// A tapped product puts its shelf row on the load one step at a time —
// the load is a bulk hand-over to a driver, not a configured sale, so the
// walk-in flow's extras/addons sheet is deliberately not in the way.
//
// Popping with the issued load is what takes the shop to its detail on
// /load. "Manage drivers" pushes /load/drivers, the shop's own-driver
// roster: the picker offers what the roster allows, so the way to change
// the offer sits beside it.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/components/categories_tab_bar.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/presentation/components/keyboard_dismisser.dart';
import 'package:base_sdk/src/presentation/components/loading/tab_bar_loading.dart';
import 'package:base_sdk/src/presentation/components/text_fields/search_text_field.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:${package}/presentation/components/orders/products_body.dart';
import 'package:${package}/presentation/routes/app_router.dart';
import 'package:orders_sdk/src/manager/application/order_products/categories/product_categories_provider.dart';
import 'package:orders_sdk/src/manager/application/order_products/order_products_provider.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';
import 'package:orders_sdk/src/manager/presentation/loads/issue_load_body.dart';

@RoutePage(name: 'ManagerIssueLoadRoute')
class IssueLoadPage extends ConsumerStatefulWidget {
  const IssueLoadPage({super.key});

  @override
  ConsumerState<IssueLoadPage> createState() => _IssueLoadPageState();
}

class _IssueLoadPageState extends ConsumerState<IssueLoadPage> {
  late final RefreshController _categoryController = RefreshController();
  late final RefreshController _productController = RefreshController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(orderProductsProvider.notifier)
          .fetchProducts(
            categoryId: null,
            isRefresh: true,
            isOpeningPage: true,
            cartStocks: const [],
          );
      ref.read(productCategoriesProvider.notifier).initialFetchCategories();
    });
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _productController.dispose();
    super.dispose();
  }

  String? _activeCategoryId() {
    final categoriesState = ref.read(productCategoriesProvider);
    return categoriesState.activeIndex == 1
        ? null
        : categoriesState.categories[categoriesState.activeIndex - 2].id;
  }

  @override
  Widget build(BuildContext context) {
    final bool isLtr = LocalStorage.getLangLtr();
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: KeyboardDismisser(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: AppStyle.surfaceFor(Theme.of(context).brightness),
          body: SafeArea(
            child: Stack(
              children: [
                IssueLoadBody(
                  pickerBuilder: _picker,
                  onIssued: (load) => Navigator.of(context).pop(load),
                  // "Manage drivers": the shop's own-driver roster, which
                  // is what the picker above is allowed to offer. The body
                  // refetches the drivers when this returns.
                  onManageDrivers: () =>
                      context.pushRoute(const ManagerShopDriversRoute()),
                ),
                PositionedDirectional(
                  end: 16,
                  bottom: 16,
                  child: FloatingBackPill(
                    back: FloatingNavBack(
                      icon: Remix.arrow_left_wide_fill,
                      label: AppHelpers.getTranslation(TrKeys.back),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The create-order flow's own picker, handing every tapped product to
  /// the body.
  Widget _picker(
    BuildContext context,
    void Function(ProductData product) onPickProduct,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Consumer(
            builder: (context, ref, child) {
              final productsEvent = ref.read(orderProductsProvider.notifier);
              return SearchTextField(
                hintText: AppHelpers.getTranslation(
                  TrKeys.searchWalkInProducts,
                ),
                onChanged: (value) => productsEvent.setQuery(
                  query: value,
                  categoryId: _activeCategoryId(),
                  cartStocks: const [],
                ),
                suffixIcon: Icon(
                  Remix.search_2_line,
                  color: AppStyle.inkFor(Theme.of(context).brightness),
                  size: 20,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Consumer(
          builder: (context, ref, child) {
            final categoriesState = ref.watch(productCategoriesProvider);
            final categoriesEvent = ref.read(
              productCategoriesProvider.notifier,
            );
            final productsEvent = ref.read(orderProductsProvider.notifier);
            return categoriesState.isLoading
                ? const TabBarLoading()
                : SizedBox(
                    height: 36,
                    child: CategoriesTabBar(
                      categories: categoriesState.categories,
                      activeIndex: categoriesState.activeIndex,
                      refreshController: _categoryController,
                      onChangeTab: (index) {
                        if (index == categoriesState.activeIndex) return;
                        categoriesEvent.setActiveIndex(index);
                        productsEvent.fetchProducts(
                          refreshController: _productController,
                          categoryId: index == 1
                              ? null
                              : categoriesState.categories[index - 2].id,
                          isRefresh: true,
                          cartStocks: const [],
                        );
                      },
                      onLoading: () => categoriesEvent.fetchMoreCategories(
                        refreshController: _categoryController,
                      ),
                    ),
                  );
          },
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Consumer(
            builder: (context, ref, child) {
              final productsState = ref.watch(orderProductsProvider);
              final productsEvent = ref.read(orderProductsProvider.notifier);
              return ProductsBody(
                loadingHeight: 130,
                bottomPadding: 12,
                isOrderFoods: true,
                isLoading: productsState.isLoading,
                products: productsState.products,
                refreshController: _productController,
                onRefreshing: () => productsEvent.fetchProducts(
                  refreshController: _productController,
                  isRefresh: true,
                  categoryId: _activeCategoryId(),
                  cartStocks: const [],
                ),
                onLoading: () => productsEvent.fetchProducts(
                  refreshController: _productController,
                  categoryId: _activeCategoryId(),
                  cartStocks: const [],
                ),
                onProductTap: (index) =>
                    onPickProduct(productsState.products[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}
