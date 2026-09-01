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

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:remixicon/remixicon.dart';

import 'package:${package}/presentation/routes/app_router.dart';
import 'package:${package}/presentation/pages/main/widgets/bottom_navigator_item.dart';
import 'package:${package}/presentation/pages/foods/edit/product_edit_page.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/presentation/adaptive/planes.dart';
import 'package:base_sdk/src/presentation/components/blur_wrap.dart';
import 'package:base_sdk/src/presentation/components/custom_network_image.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:merchants_sdk/src/manager/application/main/main_provider.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_product_data.dart';
import 'package:revenue_sdk/src/manager/application/profit/profit_dashboard_provider.dart';
import 'package:revenue_sdk/src/manager/presentation/revenue/product_profit_pane.dart';
import 'package:revenue_sdk/src/manager/presentation/revenue/revenue_workspace.dart';

/// The manager Revenue/Statistics dashboard (approved design section 36,
/// Ray 2026-08-30 10:38Z "approve all remaining 3") — the ManagerIncomePage
/// rewritten as a WORKSPACE: the dashboard declares ALL planes, tops out
/// with the FULL centered floating nav (the locked nav decision — Profile
/// tab lit, since the dashboard is entered from the profile hub), and
/// folds to the corner back pill only while the product drill-down holds a
/// plane (12:36Z). All machinery lives in the analyzable, tested package
/// code (revenue_sdk src/manager): [RevenueWorkspace] hosts the KPI /
/// chart / profit-by-product planes and the drill-down flow.
///
/// This template is a HOST file, so it owns the seams package code cannot
/// (ADR-005): the generated router (order history), merchants_sdk's tab
/// provider (the nav replica + "Set costs" → the foods tab), and
/// products_sdk (variant rows + the 674 "Edit cost price" jump into the
/// 35b edit form — decision transfer, no new form).
@RoutePage(name: 'ManagerIncomeRoute')
class ManagerIncomePage extends ConsumerStatefulWidget {
  const ManagerIncomePage({super.key});

  @override
  ConsumerState<ManagerIncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends ConsumerState<ManagerIncomePage> {
  /// Products fetched for the drill-down (variants + edit-cost handoff),
  /// keyed by docname. Fetched through the WORKING seller products list
  /// call (`get_seller_products_paginate`, searched by title) — the
  /// details endpoint's param naming predates the Frappe port and answers
  /// empty, so the list row is the honest source of stocks here.
  final Map<String, SellerProductData> _products = {};
  final Set<String> _fetching = {};

  Future<void> _ensureProduct(String id, String name) async {
    if (_products.containsKey(id) || _fetching.contains(id)) return;
    _fetching.add(id);
    try {
      final repository = GetIt.instance<SellerProductsRepositoryFacade>();
      final result = await repository.getProducts(query: name);
      result.when(
        success: (data) {
          for (final product in data.data ?? const <SellerProductData>[]) {
            if (product.id == id) {
              _products[id] = product;
            }
          }
          if (mounted) setState(() {});
        },
        failure: (error, status) {
          debugPrint('==> revenue: product lookup failed: $error');
        },
      );
    } finally {
      _fetching.remove(id);
    }
  }

  List<ProductVariantView>? _variantsFor(String id) {
    final product = _products[id];
    final stocks = product?.stocks;
    if (product == null || stocks == null || stocks.isEmpty) return null;
    return [
      for (final stock in stocks)
        ProductVariantView(
          title: (stock.extras == null || stock.extras!.isEmpty)
              ? 'standard'
              : stock.extras!
                  .map((extra) => extra.value ?? '')
                  .where((value) => value.isNotEmpty)
                  .join(' · '),
          price: stock.price,
          // The shipped schema keeps cost on the PRODUCT, not the stock
          // row — every variant margins against the same cost, honestly.
          cost: product.cost,
        ),
    ];
  }

  /// Chip 674 — the approved decision: "Edit cost price" jumps straight
  /// into the 35b product edit form (details tab carries the cost field
  /// with its "feeds profit" helper). ProductEditPage.open seeds the edit
  /// providers and pushes over the root navigator — the same fold the
  /// catalog's own edit entry makes.
  Future<void> _openEditCost(BuildContext context, String productId) async {
    final name = ref
            .read(profitDashboardProvider)
            .selectedProduct
            ?.name ??
        '';
    await _ensureProduct(productId, name);
    final product = _products[productId];
    if (product == null || !context.mounted) return;
    await ProductEditPage.open(context, ref, product);
  }

  void _goTab(int index) {
    ref.read(mainProvider.notifier).selectIndex(index);
    context.router.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLtr = LocalStorage.getLangLtr();
    // Prefetch the drilled product's stocks as soon as a row is selected,
    // so the variants section fills without a visible second tap.
    ref.listen(
        profitDashboardProvider.select((state) => state.selectedProduct),
        (previous, next) {
      if (next != null) _ensureProduct(next.id, next.name);
    });
    final selectedId = ref.watch(
        profitDashboardProvider.select((state) => state.selectedProductId));
    final shopJson = LocalStorage.getShopJson();
    final String? shopName =
        ((shopJson?['translation'] as Map?)?['title'])?.toString();

    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppStyle.surfaceDark,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // The 12:36Z fold: while the drill-down holds a plane (wide
              // widths) the workspace's PlaneHost shows the corner back
              // pill and this full nav hides. On phones the drill-down is
              // a pushed route that covers this page anyway.
              final bool wide =
                  PlaneHost.planeCountFor(constraints.maxWidth) > 1;
              final bool navFolded = wide && selectedId != null;
              return Stack(
                children: [
                  Positioned.fill(
                    child: RevenueWorkspace(
                      shopName: shopName,
                      onOrderHistory: () =>
                          context.pushRoute(const ManagerOrderHistoryRoute()),
                      // Costs are set on products — land on the foods tab.
                      onSetCosts: () => _goTab(3),
                      onEditCost: (context, productId) =>
                          _openEditCost(context, productId),
                      variantsFor: _variantsFor,
                    ),
                  ),
                  if (!navFolded)
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: _fullNav(),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// The full centered floating nav (the locked "workspace" decision):
  /// the SAME five destinations as the home shell's pill, Profile lit —
  /// a tap selects the tab on mainProvider and pops back to the shell,
  /// so the dashboard reads as a top-level surface, not a dead end.
  Widget _fullNav() {
    return BlurWrap(
      radius: BorderRadius.circular(100.r),
      child: Container(
        decoration: BoxDecoration(
          color: AppStyle.bottomNavigationBarColor.withOpacity(0.6),
          borderRadius: BorderRadius.circular(100.r),
        ),
        height: 60.r,
        child: Padding(
          padding: REdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              BottomNavigatorItem(
                isScrolling: false,
                selectItem: () => _goTab(0),
                currentIndex: 4,
                index: 0,
                selectIcon: Remix.scan_2_fill,
                unSelectIcon: Remix.scan_2_line,
              ),
              BottomNavigatorItem(
                isScrolling: false,
                selectItem: () => _goTab(1),
                currentIndex: 4,
                index: 1,
                selectIcon: Remix.file_list_2_fill,
                unSelectIcon: Remix.file_list_2_line,
              ),
              BottomNavigatorItem(
                isScrolling: false,
                selectItem: () => _goTab(2),
                currentIndex: 4,
                index: 2,
                selectIcon: Remix.bowl_fill,
                unSelectIcon: Remix.bowl_line,
              ),
              BottomNavigatorItem(
                isScrolling: false,
                selectItem: () => _goTab(3),
                currentIndex: 4,
                index: 3,
                selectIcon: Remix.restaurant_fill,
                unSelectIcon: Remix.restaurant_line,
              ),
              GestureDetector(
                // Profile is where the dashboard came from: pop home.
                onTap: () => _goTab(4),
                child: Container(
                  width: 40.r,
                  height: 40.r,
                  margin: EdgeInsets.only(left: 12.r),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppStyle.primary, width: 2.w),
                    shape: BoxShape.circle,
                  ),
                  child: CustomNetworkImage(
                    url: LocalStorage.getShopJson()?['logo_img'] as String?,
                    width: 40.r,
                    height: 40.r,
                    radius: 20.r,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
