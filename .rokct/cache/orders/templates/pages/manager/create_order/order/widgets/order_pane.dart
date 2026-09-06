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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:${package}/presentation/routes/app_router.dart';
import 'package:base_sdk/src/presentation/components/loading/loading_list.dart';
import 'package:${package}/presentation/components/orders/food_stock_item.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/title_icon.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:orders_sdk/src/manager/application/order/shipping/payment/order_payment_provider.dart';
import 'package:orders_sdk/src/manager/application/order_cart/order_cart_provider.dart';
import 'package:orders_sdk/src/manager/application/order_products/order_products_provider.dart';

/// The create-order cart — chip 681 (frames 37a/37b): title row with the
/// red Clear all, the calculated FoodStockItem lines (682 extras rows,
/// 683 slide-to-delete), the calculated subtotal row (684) and, when
/// [embedded], Next (685).
///
/// Extracted from OrderPage's body so the same pane serves both flows on
/// the SAME providers (orderCartProvider / orderPaymentProvider — no forked
/// cart state): pushed as its own page on phones (OrderPage wraps it with
/// the shop app bar and the Next | Back row), and embedded as the cart
/// PLANE beside the products plane at plane widths, where it recalculates
/// whenever the cart's stocks change instead of on route push. Hosted in
/// the walk-in plane flow, [onNext] pushes /shipping-address INTO THE
/// PLANES; null is the route push, as shipped.
class OrderPane extends ConsumerStatefulWidget {
  final bool embedded;

  /// What Next (685) does when [embedded]. Null pushes the
  /// ManagerShippingAddressRoute — the shipped behaviour.
  final VoidCallback? onNext;

  const OrderPane({super.key, this.embedded = false, this.onNext});

  @override
  ConsumerState<OrderPane> createState() => _OrderPaneState();
}

class _OrderPaneState extends ConsumerState<OrderPane> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        ref.read(orderPaymentProvider.notifier).getCalculate(
              stocks: ref.watch(orderCartProvider).stocks,
              type: 'pickup',
            );
      },
    );
  }

  void _next(BuildContext context) {
    if (widget.onNext != null) {
      widget.onNext!();
      return;
    }
    context.pushRoute(ManagerShippingAddressRoute());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      // Pushed OrderPage recalculates once on route entry; the embedded pane
      // stays on screen while products are added, so it follows the cart.
      // The cart notifier builds a new stocks list on every mutation, which
      // makes the identity check a change check.
      ref.listen(orderCartProvider, (previous, next) {
        if (previous?.stocks != next.stocks) {
          ref.read(orderPaymentProvider.notifier).getCalculate(
                stocks: next.stocks,
                type: 'pickup',
              );
        }
      });
    }
    final state = ref.watch(orderCartProvider);
    final event = ref.read(orderCartProvider.notifier);
    final paymentState = ref.watch(orderPaymentProvider);
    final paymentNotifier = ref.read(orderPaymentProvider.notifier);
    final productsEvent = ref.read(orderProductsProvider.notifier);
    final calculate = paymentState.orderCalculate;
    final int itemCount = (calculate?.stocks ?? const <Stock>[]).fold<int>(
      0,
      (sum, stock) => sum + (stock.quantity ?? 0),
    );
    return Column(
      children: [
        Padding(
          padding: REdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: 16,
          ),
          // 681: "Order" + red Clear all — the title reads on the page
          // surface in either polarity.
          child: TitleAndIcon(
            title: AppHelpers.getTranslation(TrKeys.orders),
            titleColor: AppStyle.textPrimary,
            rightTitleColor: AppStyle.red,
            rightTitle: state.stocks.isEmpty
                ? null
                : AppHelpers.getTranslation(TrKeys.clearAllOrders),
            onRightTap: () {
              event.clearAll();
              productsEvent.updateProducts(cartStocks: []);
              paymentNotifier.clearAll();
              if (!widget.embedded) {
                Navigator.pop(context);
              }
            },
          ),
        ),
        Expanded(
          child: SlidableAutoCloseBehavior(
            child: paymentState.isCalculateLoading
                ? const LoadingList(itemPadding: 2)
                : ListView.builder(
                    padding: REdgeInsets.only(
                      bottom: MediaQuery.paddingOf(context).bottom + 68,
                    ),
                    shrinkWrap: true,
                    itemCount: calculate?.stocks?.length ?? 0,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) => FoodStockItem(
                      product: calculate?.stocks?[index],
                      onDelete: () => event.deleteStockFromCart(
                        stock: calculate?.stocks?[index] ?? Stock(),
                        updateProducts: (stocks) =>
                            productsEvent.updateProducts(cartStocks: stocks),
                      ),
                    ),
                  ),
          ),
        ),
        // 684: the calculated subtotal as one quiet row — getCalculate
        // already runs on this pane; the full totals stay on
        // /delivery-time, as shipped.
        if (calculate != null &&
            state.stocks.isNotEmpty &&
            !paymentState.isCalculateLoading)
          Padding(
            padding: REdgeInsets.only(
              left: 16,
              right: 16,
              bottom: widget.embedded ? 12 : 16,
            ),
            child: _SubtotalRow(
              itemCount: itemCount,
              subtotal: calculate.price ?? 0,
            ),
          ),
        if (widget.embedded && state.stocks.isNotEmpty)
          Padding(
            padding: REdgeInsets.only(left: 16, right: 16, bottom: 16),
            // 685: Next — carries the flow step to step.
            child: CustomButton(
              title: AppHelpers.getTranslation(TrKeys.next),
              onPressed: () => _next(context),
            ),
          ),
      ],
    );
  }
}

/// Chip 684: "Subtotal · N items" and the calculated price, in the card
/// tokens — quiet, one row.
class _SubtotalRow extends StatelessWidget {
  final int itemCount;
  final num subtotal;

  const _SubtotalRow({required this.itemCount, required this.subtotal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: REdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppStyle.strokeDarkSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${AppHelpers.getTranslation(TrKeys.subtotal)} · $itemCount '
              '${AppHelpers.getTranslation(TrKeys.orderItems)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyle.interRegular(
                size: 15.sp,
                color: AppStyle.textDarkSecondary,
              ),
            ),
          ),
          8.horizontalSpace,
          Text(
            AppHelpers.numberFormat(number: subtotal),
            style: AppStyle.interSemi(
              size: 16.sp,
              color: AppStyle.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
