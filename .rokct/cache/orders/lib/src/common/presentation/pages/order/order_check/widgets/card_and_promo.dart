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
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/application/order/order_provider.dart';
import 'package:base_sdk/src/application/payment_methods/payment_provider.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:orders_sdk/src/common/presentation/pages/order/order_check/widgets/promo_code.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

import 'package:orders_sdk/src/common/presentation/pages/order/order_check/widgets/payment_method.dart';
import 'package:orders_sdk/src/common/presentation/pages/order/order_check/widgets/order_payment_container.dart';

class CardAndPromo extends StatelessWidget {
  const CardAndPromo({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Consumer(
            builder: (context, ref, child) {
              return OrderPaymentContainer(
                onTap: () {
                  AppHelpers.showCustomModalBottomSheet(
                    paddingTop: MediaQuery.paddingOf(context).top,
                    context: context,
                    modal: PaymentMethods(
                      shopEnableCod:
                          ref.watch(orderProvider).shopData?.enableCod ?? true,
                    ),
                    isDarkMode: false,
                    isDrag: true,
                    radius: 12,
                  );
                },
                icon: Icon(
                  FlutterRemix.bank_card_fill,
                  color: ((AppHelpers.getPaymentType() == "admin")
                          ? (ref.watch(paymentProvider).payments.isNotEmpty)
                          : (ref
                                  .watch(orderProvider)
                                  .shopData
                                  ?.shopPayments
                                  ?.isNotEmpty ??
                              false))
                      ? AppStyle.primary
                      : AppStyle.black,
                ),
                title: ((AppHelpers.getPaymentType() == "admin")
                        ? (ref.watch(paymentProvider).payments.isNotEmpty)
                        : (ref
                                .watch(orderProvider)
                                .shopData
                                ?.shopPayments
                                ?.isNotEmpty ??
                            false))
                    ? ((AppHelpers.getPaymentType() == "admin")
                        ? (ref
                            .watch(paymentProvider)
                            .payments[ref.watch(paymentProvider).currentIndex]
                            .tag)
                        : (ref
                                .watch(orderProvider)
                                .shopData
                                ?.shopPayments?[
                                    ref.watch(paymentProvider).currentIndex]
                                ?.payment
                                ?.tag ??
                            ""))
                    : AppHelpers.getTranslation(TrKeys.noPaymentType),
                isActive: ((AppHelpers.getPaymentType() == "admin")
                    ? (ref.watch(paymentProvider).payments.isNotEmpty)
                    : (ref
                            .watch(orderProvider)
                            .shopData
                            ?.shopPayments
                            ?.isNotEmpty ??
                        false)),
              );
            },
          ),
          Consumer(
            builder: (context, ref, child) {
              return OrderPaymentContainer(
                onTap: () {
                  AppHelpers.showCustomModalBottomSheet(
                    context: context,
                    modal: const PromoCodeScreen(),
                    isDarkMode: false,
                    isDrag: true,
                    radius: 12,
                  );
                },
                isActive: ref.watch(orderProvider).promoCode != null,
                icon: Icon(
                  FlutterRemix.ticket_line,
                  color: ref.watch(orderProvider).promoCode == null
                      ? AppStyle.black
                      : AppStyle.primary,
                ),
                title: ref.watch(orderProvider).promoCode ??
                    AppHelpers.getTranslation(TrKeys.youHavePromoCode),
              );
            },
          ),
        ],
      ),
    );
  }
}
