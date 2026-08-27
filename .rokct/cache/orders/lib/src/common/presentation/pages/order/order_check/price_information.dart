// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/application/order/order_state.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:orders_sdk/src/common/presentation/pages/order/order_check/widgets/title_price.dart';

class PriceInformation extends StatelessWidget {
  final bool isOrder;

  final OrderState state;

  const PriceInformation({
    super.key,
    required this.isOrder,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        30.verticalSpace,
        TitleAndPrice(
          title: AppHelpers.getTranslation(TrKeys.subtotal),
          rightTitle: AppHelpers.numberFormat(
            isOrder: isOrder,
            symbol: (state.orderData?.currencyModel?.symbol),
            number: isOrder
                ? state.orderData?.originPrice
                : state.calculateData?.price ?? 0,
          ),
          textStyle: AppStyle.interRegular(size: 16, color: AppStyle.black),
        ),
        16.verticalSpace,
        TitleAndPrice(
          title: AppHelpers.getTranslation(TrKeys.deliveryPrice),
          rightTitle: AppHelpers.numberFormat(
            symbol: state.orderData?.currencyModel?.symbol,
            isOrder: isOrder,
            number: isOrder
                ? (state.orderData?.deliveryFee ?? 0)
                : (state.calculateData?.deliveryFee ?? 0),
          ),
          textStyle: AppStyle.interRegular(size: 16, color: AppStyle.black),
        ),
        16.verticalSpace,
        TitleAndPrice(
          title: AppHelpers.getTranslation(TrKeys.tax),
          rightTitle: AppHelpers.numberFormat(
            isOrder: isOrder,
            symbol: state.orderData?.currencyModel?.symbol,
            number: isOrder
                ? ((state.orderData?.tax ?? 0))
                : (state.calculateData?.totalTax ?? 0),
          ),
          textStyle: AppStyle.interRegular(size: 16, color: AppStyle.black),
        ),
        16.verticalSpace,
        TitleAndPrice(
          title: AppHelpers.getTranslation(TrKeys.serviceFee),
          rightTitle: AppHelpers.numberFormat(
            isOrder: isOrder,
            symbol: state.orderData?.currencyModel?.symbol,
            number: isOrder
                ? ((state.orderData?.serviceFee ?? 0))
                : (state.calculateData?.serviceFee ?? 0),
          ),
          textStyle: AppStyle.interRegular(size: 16, color: AppStyle.black),
        ),
        16.verticalSpace,
        TitleAndPrice(
          title: AppHelpers.getTranslation(TrKeys.deliveryTip),
          rightTitle: AppHelpers.numberFormat(
            isOrder: isOrder,
            symbol: state.orderData?.currencyModel?.symbol,
            number: state.orderData?.tips ?? 0,
          ),
          textStyle: AppStyle.interRegular(size: 16, color: AppStyle.black),
        ),
        16.verticalSpace,
        if (isOrder
            ? state.orderData?.totalDiscount != null
            : state.calculateData?.totalDiscount != null)
          TitleAndPrice(
            title: AppHelpers.getTranslation(TrKeys.discount),
            rightTitle:
                "-${AppHelpers.numberFormat(isOrder: isOrder, symbol: state.orderData?.currencyModel?.symbol, number: isOrder ? (state.orderData?.totalDiscount ?? 0) : (state.calculateData?.totalDiscount ?? 0))}",
            textStyle: AppStyle.interRegular(size: 16, color: AppStyle.red),
          ),
        16.verticalSpace,
        if (isOrder
            ? state.orderData?.coupon != null
            : state.calculateData?.couponPrice != null)
          TitleAndPrice(
            title: AppHelpers.getTranslation(TrKeys.promoCode),
            rightTitle:
                "-${AppHelpers.numberFormat(isOrder: isOrder, symbol: state.orderData?.currencyModel?.symbol, number: isOrder ? (state.orderData?.coupon ?? 0) : state.calculateData?.couponPrice)}",
            textStyle: AppStyle.interRegular(size: 16, color: AppStyle.red),
          ),
        16.verticalSpace,
        const Divider(color: AppStyle.textGrey),
        16.verticalSpace,
        TitleAndPrice(
          title: AppHelpers.getTranslation(TrKeys.total),
          rightTitle: AppHelpers.numberFormat(
            isOrder: isOrder,
            symbol: state.orderData?.currencyModel?.symbol,
            number: isOrder
                ? (state.orderData?.totalPrice?.isNegative ?? true)
                    ? 0
                    : state.orderData?.totalPrice
                : state.calculateData?.totalPrice,
          ),
          textStyle: AppStyle.interSemi(size: 20, color: AppStyle.black),
        ),
      ],
    );
  }
}
