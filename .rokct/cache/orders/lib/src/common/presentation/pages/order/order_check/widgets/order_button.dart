import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/application/payment_methods/payment_provider.dart';
import 'package:base_sdk/src/application/shop_order/shop_order_provider.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:orders_sdk/src/common/presentation/pages/order/order_check/widgets/refund_screen.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

import 'package:base_sdk/src/application/order/order_provider.dart';

class OrderButton extends ConsumerWidget {
  final bool isOrder;
  final bool isLoading;
  final bool isRepeatLoading;
  final bool isAutoLoading;
  final OrderStatus orderStatus;
  final VoidCallback createOrder;
  final VoidCallback cancelOrder;
  final VoidCallback repeatOrder;
  final VoidCallback autoOrder;
  final VoidCallback callShop;
  final VoidCallback callDriver;
  final VoidCallback? showImage;
  final VoidCallback sendSmsDriver;
  final bool isRefund;

  const OrderButton({
    super.key,
    required this.isOrder,
    required this.orderStatus,
    required this.createOrder,
    required this.isAutoLoading,
    required this.isLoading,
    required this.cancelOrder,
    required this.callShop,
    required this.callDriver,
    required this.sendSmsDriver,
    required this.isRefund,
    required this.repeatOrder,
    required this.isRepeatLoading,
    required this.showImage,
    required this.autoOrder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isOrder) {
      // For existing orders, handle different order statuses
      switch (orderStatus) {
        case OrderStatus.onWay:
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: (MediaQuery.sizeOf(context).width - 60) / 2,
                child: CustomButton(
                  isLoading: isLoading,
                  background: AppStyle.black,
                  textColor: AppStyle.white,
                  title: AppHelpers.getTranslation(TrKeys.callTheDriver),
                  onPressed: callDriver,
                ),
              ),
              SizedBox(
                width: (MediaQuery.sizeOf(context).width - 60) / 2,
                child: CustomButton(
                  isLoading: isLoading,
                  background: AppStyle.black,
                  textColor: AppStyle.white,
                  title: AppHelpers.getTranslation(TrKeys.sendMessage),
                  onPressed: sendSmsDriver,
                ),
              ),
            ],
          );
        case OrderStatus.open:
          return CustomButton(
            isLoading: isLoading,
            background: AppStyle.red,
            textColor: AppStyle.white,
            title: AppHelpers.getTranslation(TrKeys.cancelOrder),
            onPressed: cancelOrder,
          );
        case OrderStatus.accepted:
        case OrderStatus.ready:
          return CustomButton(
            isLoading: isLoading,
            background: AppStyle.black,
            textColor: AppStyle.white,
            title: AppHelpers.getTranslation(TrKeys.callCenterRestaurant),
            onPressed: callShop,
          );
        case OrderStatus.delivered:
          if (isRefund) {
            return Column(
              children: [
                if (showImage != null)
                  GestureDetector(
                    onTap: showImage,
                    child: Container(
                      margin: EdgeInsets.only(top: 8.h),
                      decoration: BoxDecoration(
                        color: AppStyle.transparent,
                        border: Border.all(color: AppStyle.black, width: 2),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      padding: REdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppHelpers.getTranslation(TrKeys.orderImage),
                            style: AppStyle.interNormal(
                              size: 14.sp,
                              color: AppStyle.black,
                              letterSpacing: -0.3,
                            ),
                          ),
                          12.horizontalSpace,
                          const Icon(FlutterRemix.gallery_fill),
                        ],
                      ),
                    ),
                  ),
                10.verticalSpace,
                CustomButton(
                  isLoading: isAutoLoading,
                  background: AppStyle.transparent,
                  borderColor: AppStyle.black,
                  textColor: AppStyle.black,
                  title: AppHelpers.getTranslation(TrKeys.autoOrder),
                  onPressed: autoOrder,
                ),
                10.verticalSpace,
                CustomButton(
                  isLoading: isRepeatLoading,
                  background: AppStyle.transparent,
                  borderColor: AppStyle.black,
                  textColor: AppStyle.black,
                  title: AppHelpers.getTranslation(TrKeys.repeatOrder),
                  onPressed: repeatOrder,
                ),
                10.verticalSpace,
                CustomButton(
                  isLoading: isLoading,
                  title: AppHelpers.getTranslation(TrKeys.reFound),
                  background: AppStyle.red,
                  textColor: AppStyle.white,
                  onPressed: () {
                    AppHelpers.showCustomModalBottomSheet(
                      context: context,
                      modal: const RefundScreen(),
                      isDarkMode: false,
                    );
                  },
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        case OrderStatus.canceled:
          return const SizedBox.shrink();
      }
    } else {
      // For new orders - the checkout button
      return Consumer(
        builder: (context, ref, child) {
          final orderState = ref.watch(orderProvider);
          final paymentState = ref.watch(paymentProvider);
          final shopOrderState = ref.watch(shopOrderProvider);

          // Check if cart is not empty
          final isNotEmptyCart =
              (shopOrderState.cart?.userCarts?.first.cartDetails?.isNotEmpty ??
                  false);

          // Check if payment methods are available
          final isNotEmptyPaymentType =
              ((AppHelpers.getPaymentType() == "admin")
                  ? (paymentState.payments.isNotEmpty)
                  : (orderState.shopData?.shopPayments?.isNotEmpty ?? false));

          // Check if PayFast is selected

          // Get the total price
          final totalPrice = orderState.calculateData?.totalPrice ?? 0;

          // Set active status based on delivery type selection and date
          final bool isActive = isNotEmptyCart || isNotEmptyPaymentType
              ? (orderState.tabIndex == 0 || (orderState.selectDate != null))
              : true;

          return CustomButton(
            isLoading: isLoading,
            background: isActive ? AppStyle.primary : AppStyle.bgGrey,
            textColor: isActive ? AppStyle.black : AppStyle.textGrey,
            title:
                "${AppHelpers.getTranslation(TrKeys.continueToPayment)} — ${AppHelpers.numberFormat(number: totalPrice)}",
            onPressed: isActive ? createOrder : null,
          );
        },
      );
    }
  }
}
