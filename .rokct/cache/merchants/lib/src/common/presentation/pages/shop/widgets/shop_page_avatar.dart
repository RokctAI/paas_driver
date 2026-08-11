import 'dart:ui';
import 'package:base_sdk/src/navigation/app_routes.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
//import 'package:flutter_svg/flutter_svg.dart';
//import 'package:remixicon/remixicon.dart';
import 'package:base_sdk/src/application/shop_order/shop_order_provider.dart';
import 'package:base_sdk/src/models/data/shop_data.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
//import 'package:foodyman/presentation/components/badge_item.dart';
import 'package:base_sdk/src/presentation/components/buttons/animation_button_effect.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/custom_network_image.dart';
//import 'package:foodyman/presentation/components/shop_avarat.dart';
import 'package:merchants_sdk/src/common/presentation/pages/shop/group_order/group_order.dart';
// [refork] removed host router import
import 'package:base_sdk/src/presentation/theme/theme.dart';
import 'package:base_sdk/src/presentation/components/badges.dart';
import 'package:base_sdk/src/models/data/bonus_data.dart';
import 'package:merchants_sdk/src/common/presentation/pages/shop/widgets/bonus_screen.dart';
//import 'shop_description_item.dart';

class ShopPageAvatar extends StatelessWidget {
  final ShopData shop;
  final String? cartId;
  final String? userUuid;
  final String workTime;
  final bool isLike;
  final VoidCallback onShare;
  final VoidCallback onLike;
  final BonusModel? bonus;

  const ShopPageAvatar({
    super.key,
    required this.shop,
    required this.onLike,
    required this.workTime,
    required this.isLike,
    required this.onShare,
    required this.bonus,
    this.cartId,
    this.userUuid,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        shopAppBar(context),
        8.verticalSpace,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /*Text(
                shop.translation?.description ?? "",
                style: AppStyle.interNormal(
                  size: 13,
                  color: AppStyle.black,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              6.verticalSpace, */

              // 10.verticalSpace,
              /* Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShopDescriptionItem(
                    title: AppHelpers.getTranslation(TrKeys.workingHours),
                    description: workTime,
                    icon: const Icon(Remix.time_fill),
                  ),
                  ShopDescriptionItem(
                    title: AppHelpers.getTranslation(TrKeys.deliveryTime),
                    description:
                        "${shop.deliveryTime?.from ?? 0} - ${shop.deliveryTime?.to ?? 0} ${AppHelpers.getTranslation(shop.deliveryTime?.type ?? "min")}",
                    icon: SvgPicture.asset("assets/svgs/delivery.svg"),
                  ),
                  ShopDescriptionItem(
                    title: AppHelpers.getTranslation(TrKeys.deliveryPrice),
                    description:
                        "${AppHelpers.getTranslation(TrKeys.from)} ${AppHelpers.numberFormat(number: shop.minPrice)}",
                    icon: SvgPicture.asset(
                      "assets/svgs/ticket.svg",
                      width: 18.r,
                      height: 18.r,
                    ),
                  ),
                ],
              ),*/
              AppHelpers.getTranslation(TrKeys.close) == workTime
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        width: MediaQuery.sizeOf(context).width - 32,
                        decoration: BoxDecoration(
                          color: AppStyle.bgGrey,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Row(
                          children: [
                            const Icon(
                              Remix.time_fill,
                              color: AppStyle.black,
                            ),
                            8.horizontalSpace,
                            Expanded(
                              child: Text(
                                AppHelpers.getTranslation(
                                  TrKeys.notWorkTodayTime,
                                ),
                                style: AppStyle.interNormal(
                                  size: 14,
                                  color: AppStyle.black,
                                ),
                                textAlign: TextAlign.start,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
              bonus != null ? _bonusButton(context) : const SizedBox.shrink(),
              12.verticalSpace,
              if (AppHelpers.getGroupOrder()) groupOrderButton(context),
            ],
          ),
        ),
      ],
    );
  }

  checkOtherShop(BuildContext context) {
    AppHelpers.showAlertDialog(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppHelpers.getTranslation(TrKeys.allPreviouslyAdded),
            style: AppStyle.interNormal(),
            textAlign: TextAlign.center,
          ),
          16.verticalSpace,
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  title: AppHelpers.getTranslation(TrKeys.cancel),
                  background: AppStyle.transparent,
                  borderColor: AppStyle.borderColor,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              10.horizontalSpace,
              Expanded(
                child: Consumer(
                  builder: (contextTwo, ref, child) {
                    return CustomButton(
                      isLoading: ref.watch(shopOrderProvider).isDeleteLoading,
                      title: AppHelpers.getTranslation(TrKeys.continueText),
                      onPressed: () {
                        ref
                            .read(shopOrderProvider.notifier)
                            .deleteCart(context)
                            .then((value) async {
                          if (context.mounted) {
                            ref
                                .read(shopOrderProvider.notifier)
                                .createCart(context, (shop.id ?? ""));
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget groupOrderButton(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        ref.listen(shopOrderProvider, (previous, next) {
          if (next.isOtherShop && next.isOtherShop != previous?.isOtherShop) {
            checkOtherShop(context);
          }
          if (next.isStartGroup &&
              next.isStartGroup != previous?.isStartGroup) {
            AppHelpers.showCustomModalBottomSheet(
              context: context,
              modal: GroupOrderScreen(shop: shop, cartId: cartId),
              isDarkMode: false,
              isDrag: true,
              radius: 12,
            );
          }
        });
        bool isStartOrder =
            (ref.watch(shopOrderProvider).cart?.group ?? false) &&
                (ref.watch(shopOrderProvider).cart?.shopId == shop.id);
        return CustomButton(
          isLoading: ref.watch(shopOrderProvider).isStartGroupLoading ||
              ref.watch(shopOrderProvider).isCheckShopOrder,
          icon: Icon(
            isStartOrder
                ? Remix.list_settings_line
                : Remix.group_2_line,
            color: isStartOrder ? AppStyle.black : AppStyle.white,
          ),
          title: isStartOrder
              ? AppHelpers.getTranslation(TrKeys.manageOrder)
              : AppHelpers.getTranslation(TrKeys.startGroupOrder),
          background:
              isStartOrder ? AppStyle.primary : AppStyle.orderButtonColor,
          textColor: isStartOrder ? AppStyle.black : AppStyle.white,
          radius: 10,
          onPressed: () {
            if (LocalStorage.getToken().isNotEmpty) {
              !isStartOrder
                  ? ref
                      .read(shopOrderProvider.notifier)
                      .createCart(context, shop.id ?? "")
                  : AppHelpers.showCustomModalBottomSheet(
                      paddingTop: MediaQuery.paddingOf(context).top + 160.h,
                      context: context,
                      modal: GroupOrderScreen(shop: shop, cartId: cartId),
                      isDarkMode: false,
                      isDrag: true,
                      radius: 12,
                    );
            } else {
              AppRoutes.I.pushLoginRoute(context);
            }
          },
        );
      },
    );
  }

  Stack shopAppBar(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 180.h + MediaQuery.paddingOf(context).top,
          width: double.infinity,
          color: AppStyle.mainBack,
          child: CustomNetworkImage(
            url: shop.backgroundImg ?? "",
            height: 180.h + MediaQuery.paddingOf(context).top,
            width: double.infinity,
            radius: 0,
          ),
        ),

        /// const SizedBox(width: 10),
        RatingBadge(shop: shop),
        // shop.minPrice != 0
        DeliveryFeeBadge(shop: shop),
        Positioned(
          bottom: 20.h,
          right: 15.w,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        AppRoutes.I.pushShopDetailRoute(context, shop: shop, workTime: workTime);
                      },
                      child: Text(
                        AppHelpers.getTranslation(TrKeys.moreInfo),
                        style: AppStyle.interNormal(
                          size: 12,
                          color: AppStyle.white,
                          textDecoration: TextDecoration.underline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 20.h,
          left: 15.w,
          child: Row(
            children: [
              BonusDiscountPopular(
                isSingleShop: true,
                isPopular: shop.isRecommend ?? false,
                bonus: shop.bonus,
                isDiscount: shop.isDiscount ?? false,
              ),
            ],
          ),
        ),

        ShopBadge(shop: shop),
        DistanceBadge(shop: shop),
        Positioned(
          top: MediaQuery.paddingOf(context).top,
          right: 16.w,
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (LocalStorage.getToken().isEmpty) {
                    AppRoutes.I.replaceLoginRoute(context);
                    return;
                  }
                  AppRoutes.I.pushChatRoute(context, roleId: shop.id.toString(),
                      name: shop.translation?.title ?? "",);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      color: AppStyle.unselectedBottomBarItem.withOpacity(0.29),
                      child: const Center(
                        child: Icon(
                          Remix.chat_1_line,
                          color: AppStyle.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              8.horizontalSpace,
              GestureDetector(
                onTap: onLike,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      color: AppStyle.unselectedBottomBarItem.withOpacity(0.29),
                      child: Center(
                        child: Icon(
                          isLike
                              ? Remix.heart_3_fill
                              : Remix.heart_3_line,
                          color: AppStyle.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              8.horizontalSpace,
              GestureDetector(
                onTap: onShare,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      color: AppStyle.unselectedBottomBarItem.withOpacity(0.29),
                      child: const Center(
                        child: Icon(
                          Remix.share_line,
                          color: AppStyle.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  AnimationButtonEffect _bonusButton(BuildContext context) {
    return AnimationButtonEffect(
      child: GestureDetector(
        onTap: () {
          AppHelpers.showCustomModalBottomSheet(
            paddingTop: MediaQuery.paddingOf(context).top,
            context: context,
            modal: BonusScreen(bonus: bonus),
            isDarkMode: false,
            isDrag: true,
            radius: 12,
          );
        },
        child: Container(
          margin: EdgeInsets.only(top: 8.h),
          width: MediaQuery.sizeOf(context).width - 32,
          decoration: BoxDecoration(
            color: AppStyle.bgGrey,
            borderRadius: BorderRadius.circular(10.r),
          ),
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              Container(
                width: 22.w,
                height: 22.h,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppStyle.blueBonus,
                ),
                child: Icon(
                  Remix.gift_2_fill,
                  size: 16.r,
                  color: AppStyle.white,
                ),
              ),
              8.horizontalSpace,
              Expanded(
                child: Text(
                  bonus != null
                      ? ((bonus?.type ?? "sum") == "sum")
                          ? "${AppHelpers.getTranslation(TrKeys.under)} ${AppHelpers.numberFormat(number: bonus?.value)} + ${bonus?.bonusStock?.product?.translation?.title ?? ""}"
                          : "${AppHelpers.getTranslation(TrKeys.under)} ${bonus?.value ?? 0} + ${bonus?.bonusStock?.product?.translation?.title ?? ""}"
                      : "",
                  style: AppStyle.interNormal(size: 14, color: AppStyle.black),
                  textAlign: TextAlign.start,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
