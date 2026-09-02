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

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/models/data/shop_data.dart';
import 'package:base_sdk/src/presentation/components/custom_network_image.dart';

import 'package:base_sdk/src/constants/app_constants.dart';
//import 'package:rokctapp/presentation/pages/home_two/widget/two_bonus_discount.dart';
import 'package:base_sdk/src/presentation/components/badges/delivery_fee_badge.dart';
import 'package:base_sdk/src/presentation/components/badges/distance_badge.dart';
import 'package:base_sdk/src/presentation/components/badges/order_time_badge.dart';
import 'package:base_sdk/src/presentation/components/badges/rating_badge.dart';
import 'package:base_sdk/src/presentation/components/badges/storelogo_badge.dart';
import 'package:base_sdk/src/presentation/components/bonus_discount_popular.dart';

class MarketTwoItem extends StatelessWidget {
  final ShopData shop;
  final bool isSimpleShop;
  final bool isShop;
  final bool isFilter;
  final bool? bgImg;

  const MarketTwoItem({
    super.key,
    this.isSimpleShop = false,
    required this.shop,
    this.isShop = false,
    this.isFilter = false,
    this.bgImg,
  });

  @override
  Widget build(BuildContext context) {
    final shouldUseBgImg = bgImg ?? AppConstants.bgImg;
    final screenWidth = MediaQuery.of(context).size.width;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final isNarrow = constraints.maxWidth < screenWidth / 2;
        return GestureDetector(
          onTap: () {
            context.router.pushNamed('/shop?shopId=' + (shop.id ?? 0).toString());
          },
          child: isShop
              ? _shopItem()
              : Container(
                  margin: isFilter
                      ? const EdgeInsets.symmetric(horizontal: 16)
                      : isSimpleShop
                      ? EdgeInsets.all(8.r)
                      : EdgeInsets.only(right: 8.r),
                  width: 268.r,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(24.r)),
                    // Add border when background image is disabled
                    border: !shouldUseBgImg
                        ? Border.all(color: AppStyle.textGrey)
                        : null,
                  ),
                  child: Stack(
                    children: [
                      // Background image or Container with border - only construct the widget we need
                      if (shouldUseBgImg)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24.r),
                          child: CustomNetworkImage(
                            url: shop.backgroundImg ?? '',
                            height: double.infinity,
                            width: double.infinity,
                            radius: 0,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24.r),
                          child: Container(
                            height: double.infinity,
                            width: double.infinity,
                            color: AppStyle.textGrey.withOpacity(0.3),
                          ),
                        ),
                      DistanceBadge(
                        shop: shop,
                        bottom: isNarrow ? 98.h : 70.h,
                        //left: isNarrow ? 30.w : null
                      ),
                      ShopBadge(
                        shop: shop,
                        top: 8.h,
                        iconSize: isNarrow ? 22 : null,
                        containerHeight: isNarrow ? 30 : null,
                        containerWidth: isNarrow ? 130.w : null,
                        fontSize: isNarrow ? 10 : null,
                        maxTextLength: isNarrow ? 12 : null,
                      ),
                      DeliveryFeeBadge(
                        shop: shop,
                        right: isNarrow ? 12.w : 15.w,
                        bottom: isNarrow ? 40.h : 10.h,
                        //  left: isNarrow ? 50.w : null
                      ),
                      RatingBadge(
                        shop: shop,
                        bottom: isNarrow ? 70.h : 40.h,
                        // left: isNarrow ? 50.w : null,
                        right: isNarrow ? 12.w : null,
                        isText: isNarrow ? false : true,
                      ),
                      OpTimeBadge(
                        shop: shop,
                        top: isNarrow ? 92.h : 95.h,
                        right: isNarrow ? 12.w : 15.w,
                      ),
                      Positioned(
                        bottom: isNarrow ? 4.h : 5.h,
                        right: 0.w,
                        left: isNarrow ? 50.w : 10.w,
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: isSimpleShop ? 6.h : 0,
                          ),
                          child: BonusDiscountPopular(
                            isPopular: shop.isRecommend ?? false,
                            bonus: shop.bonus,
                            isSingleShop: false,
                            isDiscount: shop.isDiscount ?? false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _shopItem() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppStyle.bgGrey,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          23.verticalSpace,
          CustomNetworkImage(
            url: shop.logoImg ?? "",
            height: 80.r,
            width: 80.r,
            radius: 40.r,
          ),
          // const Spacer(),
        ],
      ),
    );
  }
}
