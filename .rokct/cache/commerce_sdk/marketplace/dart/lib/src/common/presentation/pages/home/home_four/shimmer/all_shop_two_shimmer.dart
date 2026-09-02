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
import 'package:base_sdk/src/presentation/components/title_icon.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:marketplace_sdk/src/common/presentation/pages/home/home_four/shimmer/market_two_shimmer.dart';

class AllShopTwoShimmer extends StatelessWidget {
  final bool isTitle;

  const AllShopTwoShimmer({super.key, this.isTitle = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        isTitle
            ? TitleAndIcon(
                rightTitle: AppHelpers.getTranslation(TrKeys.seeAll),
                isIcon: true,
                title: AppHelpers.getTranslation(TrKeys.popularNearYou),
                titleColor: AppStyle.shimmerBase,
                rightTitleColor: AppStyle.white,
                containerColor: AppStyle.shimmerBase,
                borderColor: AppStyle.shimmerBase,
                iconColor: AppStyle.white,
                onRightTap: () {},
              )
            : const SizedBox.shrink(),
        AnimationLimiter(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16.r,
              crossAxisSpacing: 16.r,
              mainAxisExtent: 230.r,
            ),
            padding: EdgeInsets.only(top: 6.h, left: 16, right: 16),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            scrollDirection: Axis.vertical,
            itemCount: 2,
            itemBuilder: (context, index) =>
                AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: MarketTwoShimmer(isSimpleShop: true, index: index),
                    ),
                  ),
                ),
          ),
        ),
      ],
    );
  }
}
