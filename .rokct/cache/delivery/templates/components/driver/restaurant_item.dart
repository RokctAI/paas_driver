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
import 'package:remixicon/remixicon.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'shop_avarat.dart';

class RestaurantItem extends StatelessWidget {
  final String shopName;
  final String shopUid;
  final String shopImage;
  final String shopText;
  final String shopId;

  const RestaurantItem({
    super.key,
    required this.shopName,
    required this.shopImage,
    required this.shopText,
    required this.shopUid,
    required this.shopId,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Container(
        height: 74.h,
        decoration: BoxDecoration(
          color: AppStyle.white,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: AppStyle.white.withOpacity(0.04),
              spreadRadius: 0,
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShopAvatar(imageUrl: shopImage, size: 50, padding: 6),
              10.horizontalSpace,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        shopName,
                        style: AppStyle.interSemi(
                          size: 15.sp,
                          color: AppStyle.black,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          left: MediaQuery.sizeOf(context).width - 220.w,
                        ),
                        child: Icon(Remix.building_fill, size: 16.r),
                      ),
                      8.horizontalSpace,
                      Text(
                        "1.3 km",
                        style: AppStyle.interRegular(
                          size: 14.sp,
                          color: AppStyle.black,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    shopText,
                    style: AppStyle.interNormal(
                      size: 12.sp,
                      color: AppStyle.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
