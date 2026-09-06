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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'widgets/payment_item.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:${package}/presentation/pages/create_order/order/widgets/title_price.dart';
import 'package:${package}/presentation/component/select_date_modal.dart';
import 'package:base_sdk/src/presentation/adaptive/planes.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/presentation/components/keyboard_dismisser.dart';
import 'package:base_sdk/src/presentation/components/loading.dart';
import 'package:base_sdk/src/presentation/components/title_icon.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:orders_sdk/src/manager/application/order/create_order_provider.dart';
import 'package:orders_sdk/src/manager/application/order/shipping/address/order/order_address_provider.dart';
import 'package:orders_sdk/src/manager/application/order/shipping/delivery/delivery_type_provider.dart';
import 'package:orders_sdk/src/manager/application/order/shipping/payment/order_payment_provider.dart';
import 'package:orders_sdk/src/manager/application/order/shipping/section/section_provider.dart';
import 'package:orders_sdk/src/manager/application/order/shipping/table/table_provider.dart';
import 'package:orders_sdk/src/manager/application/order/shipping/time/delivery_time_provider.dart';
import 'package:orders_sdk/src/manager/application/order/shipping/user/order_user_provider.dart';
import 'package:orders_sdk/src/manager/application/order_cart/order_cart_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/appbar/home_appbar_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/new/new_orders_provider.dart';

// PLACE ORDER — /delivery-time, the finish step (frame 37e): the
// delivery-time card (696, its row opening the SelectDateModal — a sheet,
// never a plane), the payment-method rows fetched per delivery type (697;
// the shipped wallet guard compares the balance to the total) and the
// calculate summary card (698 — the shipped order_calculate fields).
// "Place order · total" (699) creates the order — the shipped success path
// pops to root, clears the cart and refreshes the board — and the shipped
// offline path is told in one honest line under the button: no connection
// means the order queues on this device and syncs (the queued op carries
// the payment id; the sync handler finishes the transaction). Hosted in
// the walk-in plane flow it declares the DEFAULT one plane, takes the LAST
// one, and docks Place order at its foot — the host draws the corner Back
// pill; on the pushed phone route Place order sits at the START and the
// corner pill (347) at the END. popUntilRoot leaves the walk-in route
// under either width, so the flow ends the same way it always did.
@RoutePage(name: 'ManagerDeliveryTimeRoute')
class DeliveryTimePage extends ConsumerStatefulWidget {
  const DeliveryTimePage({super.key});

  @override
  ConsumerState<DeliveryTimePage> createState() => _DeliveryTimePageState();
}

class _DeliveryTimePageState extends ConsumerState<DeliveryTimePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        ref.read(orderPaymentProvider.notifier)
          ..fetchPayments(ref.watch(deliveryTypeProvider).type)
          ..getCalculate(
            stocks: ref.watch(orderCartProvider).stocks,
            type: ref.watch(deliveryTypeProvider).type,
            location: ref.watch(orderAddressProvider).location,
          );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Hosted in the walk-in planes (37e's step at plane widths)? Then the
    // host owns the corner pill and Place order docks under the cards.
    final Planes? planes = Planes.maybeOf(context);
    final bool hosted = planes != null && planes.count > 1;
    return KeyboardDismisser(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppStyle.surfaceDark,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The 171-pattern bare title: "Place order".
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 16.h),
                    child: Text(
                      AppHelpers.getTranslation(TrKeys.placeOrder),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyle.interSemi(
                        size: 24,
                        color: AppStyle.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(child: _cards(context, hosted: hosted)),
                  if (hosted)
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                      child: _placeOrder(context),
                    ),
                ],
              ),
              // The phone route: Place order (699) at the START with its
              // offline line, the corner Back pill (347) at the END.
              if (!hosted)
                PositionedDirectional(
                  start: 16,
                  end: 16,
                  bottom: 16,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: _placeOrder(context)),
                      8.horizontalSpace,
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
          ),
        ),
      ),
    );
  }

  /// 696 / 697 / 698 — the shipped cards, scrolling under the title.
  Widget _cards(BuildContext context, {required bool hosted}) {
    return Container(
          padding: MediaQuery.viewInsetsOf(context),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16.w,
              right: 16.w,
              // Room under the last card for the floating row on the
              // phone route; the hosted pane docks the button below.
              bottom: hosted ? 24.h : 140.h,
            ),
            child: Column(
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    return Container(
                      decoration: BoxDecoration(
                        color: AppStyle.white,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      padding: REdgeInsets.only(
                        top: 24,
                        left: 16,
                        right: 16,
                        bottom: 16,
                      ),
                      child: Consumer(
                        builder: (context, ref, child) {
                          final timeState = ref.watch(deliveryTimeProvider);
                          final timeEvent =
                              ref.read(deliveryTimeProvider.notifier);
                          return Column(
                            children: [
                              TitleAndIcon(
                                title: AppHelpers.getTranslation(
                                    TrKeys.deliveryTime),
                              ),
                              24.verticalSpace,
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppHelpers.getTranslation(
                                        TrKeys.selectedTimeAndDay),
                                    style: AppStyle.interSemi(
                                        size: 14.sp, letterSpacing: -0.3),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        AppHelpers.showCustomModalBottomSheet(
                                      paddingTop:
                                          MediaQuery.paddingOf(context).top,
                                      context: context,
                                      radius: 12,
                                      modal: SelectDateModal(
                                        initialDate: timeState.deliveryDate,
                                        onDateSaved: (date) =>
                                            timeEvent.setDeliveryDate(
                                          date.toString().substring(0, 10),
                                        ),
                                      ),
                                      isDarkMode: true,
                                    ),
                                    child: Text(
                                      timeState.deliveryDate,
                                      style: AppStyle.interNormal(
                                          size: 14.sp, letterSpacing: -0.3),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
                Consumer(
                  builder: (context, ref, child) {
                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 10.h),
                      decoration: BoxDecoration(
                        color: AppStyle.white,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      padding: REdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      child: Column(
                        children: [
                          TitleAndIcon(
                            title: AppHelpers.getTranslation(TrKeys.payment),
                          ),
                          Consumer(
                            builder: (context, ref, child) {
                              final paymentState =
                                  ref.watch(orderPaymentProvider);
                              final paymentEvent =
                                  ref.watch(orderPaymentProvider.notifier);
                              return paymentState.isLoading
                                  ? Container(
                                      width: 30.r,
                                      height: 30.r,
                                      margin:
                                          REdgeInsets.symmetric(vertical: 20),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3.r,
                                          color: AppStyle.primary,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: paymentState.payments.length,
                                      shrinkWrap: true,
                                      padding:
                                          REdgeInsets.symmetric(vertical: 18),
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, index) =>
                                          PaymentItem(
                                        payment: paymentState.payments[index],
                                        isSelected:
                                            paymentState.selectedIndex == index,
                                        isLast: paymentState.payments.length ==
                                            index + 1,
                                        onTap: () => paymentEvent
                                            .setSelectedIndex(index),
                                      ),
                                    );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Consumer(builder: (context, ref, child) {
                  final state = ref.watch(orderPaymentProvider);
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 10.h),
                    decoration: BoxDecoration(
                      color: AppStyle.white,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    child: state.isCalculateLoading
                        ? const Loading()
                        : Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: TitleAndIcon(
                                  title:
                                      "${AppHelpers.getTranslation(TrKeys.payment)} - \$",
                                ),
                              ),
                              24.verticalSpace,
                              TitleAndPrice(
                                title:
                                    AppHelpers.getTranslation(TrKeys.subtotal),
                                rightTitle: AppHelpers.numberFormat(number: state.orderCalculate?.price ?? 0),
                                textStyle: AppStyle.interRegular(
                                  size: 16,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              16.verticalSpace,
                              TitleAndPrice(
                                title: AppHelpers.getTranslation(
                                    TrKeys.deliveryPrice),
                                rightTitle: AppHelpers.numberFormat(number: state.orderCalculate?.deliveryFee ?? 0),
                                textStyle: AppStyle.interRegular(
                                    size: 16, letterSpacing: -0.3),
                              ),
                              16.verticalSpace,
                              TitleAndPrice(
                                title: AppHelpers.getTranslation(
                                    TrKeys.serviceFee),
                                rightTitle: AppHelpers.numberFormat(number: state.orderCalculate?.serviceFee ?? 0),
                                textStyle: AppStyle.interRegular(
                                    size: 16, letterSpacing: -0.3),
                              ),
                              16.verticalSpace,
                              TitleAndPrice(
                                title:
                                    AppHelpers.getTranslation(TrKeys.discount),
                                rightTitle:
                                    '-${AppHelpers.numberFormat(number: state.orderCalculate?.totalDiscount ?? 0)}',
                                textStyle: AppStyle.interRegular(
                                    size: 16, letterSpacing: -0.3),
                              ),
                              16.verticalSpace,
                              TitleAndPrice(
                                title:
                                    AppHelpers.getTranslation(TrKeys.totalTax),
                                rightTitle: AppHelpers.numberFormat(number: state.orderCalculate?.totalShopTax ?? 0),
                                textStyle: AppStyle.interRegular(
                                    size: 16, letterSpacing: -0.3),
                              ),
                              16.verticalSpace,
                              Divider(color: AppStyle.shimmerBase),
                              16.verticalSpace,
                              TitleAndPrice(
                                title: AppHelpers.getTranslation(TrKeys.total),
                                rightTitle: AppHelpers.numberFormat(number: state.orderCalculate?.totalPrice ?? 0),
                                textStyle: AppStyle.interSemi(
                                    size: 20, letterSpacing: -0.3),
                              ),
                            ],
                          ),
                  );
                }),
              ],
            ),
          ),
        );
  }

  /// 699 — "Place order · total" and the honest offline line under it.
  Widget _placeOrder(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Consumer(
                  builder: (context, ref, child) {
                    final addressState = ref.watch(orderAddressProvider);
                    final paymentState = ref.watch(orderPaymentProvider);
                    final userState = ref.watch(orderUserProvider);
                    final num total =
                        paymentState.orderCalculate?.totalPrice ?? 0;
                    return CustomButton(
                      title:
                          '${AppHelpers.getTranslation(TrKeys.placeOrder)} • '
                          '${AppHelpers.numberFormat(number: total)}',
                      isLoading: ref.watch(createOrderProvider).isCreating,
                      onPressed: paymentState.payments.isEmpty
                          ? null
                          : () {
                        if (paymentState.payments[paymentState.selectedIndex]
                                .payment?.tag ==
                            'wallet') {
                          final num walletPrice =
                              userState.selectedUser?.wallet?.price ?? 0;
                          final num orderPrice =
                              paymentState.orderCalculate?.totalPrice ?? 0;
                          if (walletPrice < orderPrice) {
                            AppHelpers.showCheckTopSnackBar(
                              context,
                              AppHelpers.getTranslation(
                                  TrKeys.notEnoughMoney),
                            );
                            return;
                          }
                        }
                        ref.read(createOrderProvider.notifier).createOrder(
                              deliveryType:
                                  ref.watch(deliveryTypeProvider).type,
                              user: userState.selectedUser,
                              stocks: ref
                                      .watch(orderPaymentProvider)
                                      .orderCalculate
                                      ?.stocks ??
                                  ref.watch(orderCartProvider).stocks,
                              deliveryDate:
                                  ref.watch(deliveryTimeProvider).deliveryDate,
                              address: addressState.textController?.text ?? '',
                              location: addressState.location,
                              entrance: addressState.entrance,
                              floor: addressState.floor,
                              house: addressState.house,
                              paymentId: paymentState
                                  .payments[paymentState.selectedIndex]
                                  .payment
                                  ?.id,
                              orderSuccess: (String orderId) {
                                context.router.popUntilRoot();
                                ref.read(orderCartProvider.notifier).clearAll();
                                ref
                                    .read(orderUserProvider.notifier)
                                    .clearSelectedUserInfo();
                                ref
                                    .read(tableProvider.notifier)
                                    .clearSelectTableInfo();
                                ref
                                    .read(sectionProvider.notifier)
                                    .clearSelectSectionInfo();
                                ref
                                    .read(newOrdersProvider.notifier)
                                    .fetchNewOrders(
                                      context: context,
                                      isRefresh: true,
                                      activeTabIndex:
                                          ref.watch(homeAppbarProvider).index,
                                    );
                                ref
                                    .read(orderPaymentProvider.notifier)
                                    .createTransaction(
                                        context,
                                        orderId,
                                        paymentState
                                            .payments[
                                                paymentState.selectedIndex]
                                            .payment
                                            ?.id);
                              },
                              // Sale queued locally (backend unreachable):
                              // same cleanup, but no createTransaction — the
                              // queued op carries payment_id and the sync
                              // handler creates the transaction after the
                              // order lands.
                              orderQueued: (String localId) {
                                context.router.popUntilRoot();
                                ref.read(orderCartProvider.notifier).clearAll();
                                ref
                                    .read(orderUserProvider.notifier)
                                    .clearSelectedUserInfo();
                                ref
                                    .read(tableProvider.notifier)
                                    .clearSelectTableInfo();
                                ref
                                    .read(sectionProvider.notifier)
                                    .clearSelectSectionInfo();
                                ref
                                    .read(newOrdersProvider.notifier)
                                    .fetchNewOrders(
                                      context: context,
                                      isRefresh: true,
                                      activeTabIndex:
                                          ref.watch(homeAppbarProvider).index,
                                    );
                              },
                              failed: (message) =>
                                  AppHelpers.showCheckTopSnackBar(
                                context,
                                message,
                              ),
                              tableId: ref.watch(tableProvider).selectTable?.id,
                            );
                      },
                    );
                  },
        ),
        8.verticalSpace,
        // The shipped orderQueued path, told in one line: offline, the
        // order queues on this device and syncs.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Remix.wifi_off_line,
              size: 14.r,
              color: AppStyle.textDarkSecondary,
            ),
            6.horizontalSpace,
            Expanded(
              child: Text(
                AppHelpers.getTranslation(TrKeys.offlineOrderQueuesAndSyncs),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppStyle.interRegular(
                  size: 12.sp,
                  color: AppStyle.textDarkSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
