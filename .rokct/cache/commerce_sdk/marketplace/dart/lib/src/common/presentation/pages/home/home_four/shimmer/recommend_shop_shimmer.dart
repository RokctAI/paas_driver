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
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/title_icon.dart';

class RecommendShopShimmer extends StatelessWidget {
  const RecommendShopShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TitleAndIcon(
          rightTitle: AppHelpers.getTranslation(TrKeys.seeAll),
          isIcon: true,
          title: AppHelpers.getTranslation(TrKeys.recommended),
          titleColor: AppStyle.shimmerBase,
          rightTitleColor: AppStyle.white,
          containerColor: AppStyle.shimmerBase,
          borderColor: AppStyle.shimmerBase,
          iconColor: AppStyle.white,
          onRightTap: () {},
        ),
        12.verticalSpace,
        SizedBox(
          height: 170.h,
          child: AnimationLimiter(
            child: ListView.builder(
              shrinkWrap: false,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: 4,
              itemBuilder: (context, index) =>
                  AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: Container(
                          margin: EdgeInsets.only(left: 0, right: 9.r),
                          width: MediaQuery.sizeOf(context).width / 3,
                          height: 190.h,
                          decoration: BoxDecoration(
                            color: AppStyle.shimmerBase,
                            borderRadius: BorderRadius.all(
                              Radius.circular(10.r),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
            ),
          ),
        ),
        30.verticalSpace,
      ],
    );
  }
}
