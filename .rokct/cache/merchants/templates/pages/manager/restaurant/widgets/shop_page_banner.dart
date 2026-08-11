import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:${package}/presentation/component/helper/common_image.dart';
import 'package:${package}/presentation/component/helper/shop_bordered_avatar.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:merchants_sdk/src/manager/application/restaurant/restaurant_provider.dart';

// Ported from paas_manager lib/presentation/pages/restaurant/widgets/
// shop_page_banner.dart. LocalStorage fallbacks read the raw shop JSON —
// base_sdk keeps the shop untyped (getShopJson); legacy Style.greyColor
// (0xFFF4F5F8) maps to AppStyle.bgGrey (same value).
class ShopBanner extends StatelessWidget {
  const ShopBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      snap: true,
      floating: true,
      expandedHeight: 200.h,
      toolbarHeight: 56.h,
      backgroundColor: AppStyle.white,
      flexibleSpace: Consumer(
        builder: (context, ref, child) {
          final state = ref.watch(restaurantProvider);
          final shopJson = LocalStorage.getShopJson();
          return FlexibleSpaceBar(
            title: Stack(
              children: [
                Positioned(
                  bottom: 8.r,
                  left: 16.r,
                  child: ShopBorderedAvatar(
                    imageUrl: state.shop?.logoImg ??
                        (shopJson?['logo_img'] as String?),
                    imageSize: 36,
                    size: 46,
                    borderRadius: 12,
                    bgColor: AppStyle.bgGrey.withOpacity(0.65),
                  ),
                ),
                Positioned(
                  top: 8.r,
                  left: 72.r,
                  child: Text(
                    '${state.shop?.translation?.title ?? shopJson?['translation']?['title']}',
                    style: AppStyle.interSemi(
                      size: 16.sp,
                      color: AppStyle.blackColor,
                    ),
                  ),
                ),
              ],
            ),
            titlePadding: REdgeInsets.only(
              top: MediaQuery.paddingOf(context).top,
            ),
            background: Padding(
              padding: EdgeInsets.only(bottom: 32.h),
              child: Container(
                height: 150.h + MediaQuery.paddingOf(context).top,
                width: double.infinity,
                color: AppStyle.bgGrey,
                child: CommonImage(
                  url: state.shop?.backgroundImg ??
                      (shopJson?['background_img'] as String?),
                  width: double.infinity,
                  radius: 0,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
