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
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/models/data/shop_data.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/custom_network_image.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/navigation/app_routes.dart';

class BannerScreen extends StatelessWidget {
  final String image;
  final String bannerId;
  final String desc;
  final bool isAds;
  final List<ShopData> list;

  const BannerScreen({
    super.key,
    required this.image,
    required this.desc,
    required this.list,
    required this.bannerId,
    this.isAds = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppStyle.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8.r),
          topRight: Radius.circular(8.r),
        ),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 192.h,
            width: MediaQuery.sizeOf(context).width,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8.r),
                topRight: Radius.circular(8.r),
              ),
              child: CustomNetworkImage(
                url: image,
                height: double.infinity,
                width: double.infinity,
                radius: 0,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Text(
              desc,
              style: AppStyle.interRegular(
                size: 14.sp,
                color: AppStyle.textGrey,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Expanded(
                  child: CustomButton(
                    background: AppStyle.transparent,
                    borderColor: AppStyle.tabBarBorderColor,
                    title: AppHelpers.getTranslation(TrKeys.cancel),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                10.horizontalSpace,
                Expanded(
                  child: CustomButton(
                    title: AppHelpers.getTranslation(TrKeys.orderNow),
                    onPressed: () {
                      AppRoutes.I.pushShopsBannerRoute(
                        context,
                        bannerId: bannerId,
                        title: desc,
                        isAds: isAds,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          16.verticalSpace,
        ],
      ),
    );
  }
}
