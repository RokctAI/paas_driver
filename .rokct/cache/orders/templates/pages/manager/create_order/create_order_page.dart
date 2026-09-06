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
import 'package:auto_route/auto_route.dart';
import 'package:remixicon/remixicon.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:${package}/presentation/routes/app_router.dart';

import 'package:base_sdk/src/presentation/adaptive/planes.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:${package}/presentation/pages/create_order/details/food_details_modal.dart';
import 'package:${package}/presentation/pages/create_order/order/widgets/order_pane.dart';
import 'package:${package}/presentation/pages/create_order/shipping/address/select_address_page.dart';
import 'package:${package}/presentation/pages/create_order/shipping/details/delivery_time_page.dart';
import 'package:${package}/presentation/pages/create_order/shipping/shipping_address_page.dart';
import 'package:base_sdk/src/presentation/components/loading/tab_bar_loading.dart';
import 'package:base_sdk/src/presentation/components/categories_tab_bar.dart';
import 'package:${package}/presentation/components/orders/products_body.dart';
import 'package:${package}/presentation/pages/main/widgets/buttons_bouncing_effect.dart';
import 'package:base_sdk/src/presentation/components/keyboard_dismisser.dart';
import 'package:base_sdk/src/presentation/components/text_fields/search_text_field.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:orders_sdk/src/manager/application/order_cart/order_cart_provider.dart';
import 'package:orders_sdk/src/manager/application/order_products/categories/product_categories_provider.dart';
import 'package:orders_sdk/src/manager/application/order_products/order_products_provider.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';
import 'package:orders_sdk/src/manager/presentation/walk_in/walk_in_board_rail.dart';
import 'package:orders_sdk/src/manager/presentation/walk_in/walk_in_plane_flow.dart';

// THE WALK-IN ORDER — /order-products, the root of the shipped create-order
// chain (commerce#79), re-laid on planes per approved design strip section
// 37 (frames 37a–37e, Ray 2026-08-30 12:23Z "build authorized"). The
// state is untouched — the same orderCartProvider / orderProductsProvider /
// orderPaymentProvider run under every width — this is composition only.
//
// PLANE WIDTHS (37a–37c): the page is a WalkInPlaneFlow (package code,
// tested at 1280/800/393) whose root is the yielded orders board — the
// origin echo the plane model prescribes (675: the ALL-declaring board of
// section 33 compressed to a one-plane rail) — and whose active step is
// this page claiming TWO, spread products | cart: exactly what the old
// SplitPane did at expanded width, now produced by the declaration.
// Next on the cart pane pushes /shipping-address INTO THE PLANES (default
// claim, last plane; the board pops off stage — 37b); the map-pin pushes
// /select-address claiming ALL with no neighbours (37c); Next again pushes
// /delivery-time (the finish). The phone-only /order push DISSOLVES here:
// the cart pane is already on stage (decision (a), locked 12:23Z). A
// product tap takes the SHEET FORK (12:02Z): the shipped FoodDetailsModal
// is a pane in the last plane, not a sheet. The host's corner Back pill
// (347, bottom-END) is the one nav affordance and pops the NEWEST step;
// at the root it pops this route and the board re-expands.
//
// ONE PLANE (37d): the shipped compact layout — search (318), chips (349),
// the full-width product rows with the amber in-cart blocks (678/679/680)
// — with the shipped pop | Ordering FAB pair re-housed in the two-state
// language: the "Ordering · total" continuation (690) at the START pushes
// /order (the cart IS its own pushed page on a phone), and Back is the
// corner pill (347) at the END. From there the cascade is the plain push
// chain: /order → /shipping-address → /select-address → /delivery-time.
//
// Header: the 171-pattern bare title ("Walk-in order") on the page
// surface — no app-bar block (Ray 2026-08-28).
//
// Not changed by this composition (disclosed): the shipped row widgets
// (OrderFoodItem, FoodStockItem, the shipping / payment cards) keep their
// shipped dress — their dark redress belongs to the dark-mode fleet
// wave, not to the plane layout; the /select-user, /select-section and
// /select-table pickers stay pushed routes (list-picker family, group J —
// not framed in section 37).

@RoutePage(name: 'ManagerCreateOrderRoute')
class CreateOrderPage extends ConsumerStatefulWidget {
  const CreateOrderPage({super.key});

  @override
  ConsumerState<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends ConsumerState<CreateOrderPage> {
  late RefreshController _categoryController;
  late RefreshController _productController;

  @override
  void initState() {
    super.initState();
    _categoryController = RefreshController();
    _productController = RefreshController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(orderProductsProvider.notifier)
          .fetchProducts(
            categoryId: null,
            isRefresh: ref.watch(productCategoriesProvider).activeIndex != 1
                ? true
                : false,
            isOpeningPage: true,
            cartStocks: ref.watch(orderCartProvider).stocks,
          );
      ref.read(productCategoriesProvider.notifier).initialFetchCategories();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _categoryController.dispose();
    _productController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLtr = LocalStorage.getLangLtr();
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: KeyboardDismisser(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: AppStyle.surfaceDark,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // The plane count the host would grant this width — the
                // same rule PlaneHost applies (BoardLayoutSwitch's
                // precedent): one plane is the phone page (37d), two or
                // more the cascade (37a–37c).
                if (PlaneHost.planeCountFor(constraints.maxWidth) == 1) {
                  return _compact(context);
                }
                return _cascade(context);
              },
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // 37a–37c — the cascade
  // -------------------------------------------------------------------

  Widget _cascade(BuildContext context) {
    return WalkInPlaneFlow(
      backIcon: Remix.arrow_left_wide_fill,
      // 347 at the root: pops the whole walk-in step; the board beneath
      // this route re-expands to its ALL claim.
      onExit: () => context.maybePop(),
      // 675: the yielded board rail on plane 1.
      boardRailBuilder: (context) => const WalkInBoardRail(),
      // 318/349/678–680: the products plane; a row tap takes the sheet
      // fork — the details pane in the last plane.
      productsBuilder: (context, flow) =>
          _productsColumn(context, onProductTap: flow.openFoodDetails),
      // 681–685: the cart pane, Next carrying the flow to shipping.
      cartBuilder: (context, flow) =>
          OrderPane(embedded: true, onNext: flow.openShipping),
      foodDetailsBuilder: (context, product, flow) =>
          _FoodDetailsPane(product: product),
      // 686–689: shipping as a one-plane step; its map-pin opens 37c.
      shippingBuilder: (context, flow) => ShippingAddressPage(
        onNext: flow.openDeliveryTime,
        onSelectAddress: flow.openAddress,
      ),
      // 691–695: the map, full-bleed; Confirm writes back and pops.
      addressBuilder: (context, flow) =>
          SelectAddressPage(onClose: flow.closeAddress),
      // 696–699: the finish step. Its success/queued paths pop to root,
      // which leaves this route (and the flow with it), as shipped.
      deliveryTimeBuilder: (context, flow) => const DeliveryTimePage(),
    );
  }

  // -------------------------------------------------------------------
  // 37d — one plane, the shipped compact page re-housed
  // -------------------------------------------------------------------

  Widget _compact(BuildContext context) {
    return Stack(
      children: [
        _productsColumn(
          context,
          // On the phone the details stay the shipped drag sheet.
          onProductTap: (product) => AppHelpers.showCustomModalBottomDragSheet(
            paddingTop: 60,
            context: context,
            // base_sdk's drag sheet has no initSize knob -
            // it opens at maxChildSize; legacy opened at 0.6.
            maxChildSize: 0.8,
            modal: (c) => FoodDetailsModal(controller: c, product: product),
          ),
        ),
        // The shipped pop | Ordering pair, sides swapped per the settled
        // two-state rule: 690 at the START, the corner Back pill (347) at
        // the END — 16 logical in from both edges, as PlaneHost parks it.
        PositionedDirectional(
          start: 16,
          end: 16,
          bottom: 16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Consumer(
                builder: (context, ref, child) {
                  final cartState = ref.watch(orderCartProvider);
                  return cartState.stocks.isNotEmpty
                      ? _orderingPill(context, cartState.totalPrice)
                      : const SizedBox.shrink();
                },
              ),
              const Spacer(),
              FloatingBackPill(
                back: FloatingNavBack(
                  icon: Remix.arrow_left_wide_fill,
                  label: AppHelpers.getTranslation(TrKeys.back),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Chip 690: the "Ordering · total" continuation — the shipped FAB,
  /// black total chip on primary — pushing /order, the cart's own pushed
  /// page on a phone.
  Widget _orderingPill(BuildContext context, num total) {
    return ButtonsBouncingEffect(
      child: GestureDetector(
        onTap: () => context.pushRoute(const ManagerOrderRoute()),
        child: Container(
          height: 48.r,
          decoration: BoxDecoration(
            color: AppStyle.primary,
            borderRadius: BorderRadius.circular(10.r),
          ),
          padding: REdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Row(
            children: [
              Text(
                AppHelpers.getTranslation(TrKeys.ordering),
                style: AppStyle.interSemi(
                  size: 16.sp,
                  color: AppStyle.blackColor,
                ),
              ),
              10.horizontalSpace,
              Container(
                height: 32.r,
                padding: REdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppStyle.blackColor,
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Text(
                  AppHelpers.numberFormat(number: total),
                  style: AppStyle.interSemi(
                    size: 16.sp,
                    color: AppStyle.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // The products column — the same widgets under every width
  // -------------------------------------------------------------------

  Widget _productsColumn(
    BuildContext context, {
    required void Function(ProductData product) onProductTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The 171-pattern bare title on the page surface.
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 0),
          child: Text(
            AppHelpers.getTranslation(TrKeys.walkInOrder),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppStyle.interSemi(size: 24, color: AppStyle.textPrimary),
          ),
        ),
        16.verticalSpace,
        // Canonical 318: the product search field with the filter suffix
        // (the approved 11m search-plus-chips language).
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Consumer(
            builder: (context, ref, child) {
              final productsEvent = ref.read(orderProductsProvider.notifier);
              final categoriesState = ref.watch(productCategoriesProvider);
              return SearchTextField(
                hintText: AppHelpers.getTranslation(
                  TrKeys.searchWalkInProducts,
                ),
                onChanged: (value) => productsEvent.setQuery(
                  query: value,
                  categoryId: categoriesState.activeIndex == 1
                      ? null
                      : categoriesState
                            .categories[categoriesState.activeIndex - 2]
                            .id,
                  cartStocks: ref.watch(orderCartProvider).stocks,
                ),
                suffixIcon: Icon(
                  Remix.equalizer_fill,
                  color: AppStyle.textPrimary,
                  size: 20.r,
                ),
              );
            },
          ),
        ),
        16.verticalSpace,
        // Canonical 349: the category chip bar.
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
                    height: 36.h,
                    child: CategoriesTabBar(
                      categories: categoriesState.categories,
                      activeIndex: categoriesState.activeIndex,
                      refreshController: _categoryController,
                      onChangeTab: (index) {
                        categoriesEvent.setActiveIndex(index);
                        if (index != categoriesState.activeIndex) {
                          productsEvent.fetchProducts(
                            refreshController: _productController,
                            categoryId: index == 1
                                ? null
                                : categoriesState.categories[index - 2].id,
                            isRefresh: true,
                            cartStocks: ref.watch(orderCartProvider).stocks,
                          );
                        }
                      },
                      onLoading: () => categoriesEvent.fetchMoreCategories(
                        refreshController: _categoryController,
                      ),
                    ),
                  );
          },
        ),
        8.verticalSpace,
        // 678 the shipped OrderFoodItem rows, 679 the out-of-stock state,
        // 680 the amber in-cart quantity block on the row's edge.
        Expanded(
          child: Consumer(
            builder: (context, ref, child) {
              final productsState = ref.watch(orderProductsProvider);
              final categoriesState = ref.watch(productCategoriesProvider);
              final productsEvent = ref.read(orderProductsProvider.notifier);
              return ProductsBody(
                loadingHeight: 130,
                // Room under the last row for the floating bottom row.
                bottomPadding: 120,
                isOrderFoods: true,
                isLoading: productsState.isLoading,
                products: productsState.products,
                refreshController: _productController,
                onRefreshing: () => productsEvent.fetchProducts(
                  cartStocks: ref.watch(orderCartProvider).stocks,
                  refreshController: _productController,
                  isRefresh: true,
                  categoryId: categoriesState.activeIndex == 1
                      ? null
                      : categoriesState
                            .categories[categoriesState.activeIndex - 2]
                            .id,
                ),
                onLoading: () => productsEvent.fetchProducts(
                  refreshController: _productController,
                  cartStocks: ref.watch(orderCartProvider).stocks,
                  categoryId: categoriesState.activeIndex == 1
                      ? null
                      : categoriesState
                            .categories[categoriesState.activeIndex - 2]
                            .id,
                ),
                onProductTap: (index) =>
                    onProductTap(productsState.products[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// The sheet fork at plane widths (12:02Z): the shipped FoodDetailsModal
/// hosted as a PANE in the last plane — the same widget the phone sheet
/// shows, on its own scroll controller. Back (the host's pill) pops the
/// pane; adding to the cart updates the cart pane beside it live.
class _FoodDetailsPane extends StatefulWidget {
  final ProductData product;

  const _FoodDetailsPane({required this.product});

  @override
  State<_FoodDetailsPane> createState() => _FoodDetailsPaneState();
}

class _FoodDetailsPaneState extends State<_FoodDetailsPane> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppStyle.surfaceDark,
      child: Padding(
        padding: EdgeInsets.only(top: 24.h),
        child: FoodDetailsModal(controller: _controller, product: widget.product),
      ),
    );
  }
}
