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


import 'package:auto_route/auto_route.dart';
import 'package:base_sdk/src/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:base_sdk/src/application/order/order_provider.dart';
import 'package:base_sdk/src/application/profile/profile_provider.dart';
import 'package:base_sdk/src/application/shop_order/shop_order_provider.dart';
import 'package:base_sdk/src/models/data/address_old_data.dart';
import 'package:base_sdk/src/models/data/location.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/keyboard_dismisser.dart';
import 'package:base_sdk/src/presentation/components/title_icon.dart';
// [refork] removed host router import
import 'package:base_sdk/src/presentation/theme/app_style.dart';

import 'package:base_sdk/src/application/home/home_provider.dart';
import 'package:base_sdk/src/presentation/components/select_address_item.dart';

class SelectAddressScreen extends ConsumerStatefulWidget {
  final VoidCallback addAddress;

  const SelectAddressScreen({super.key, required this.addAddress});

  @override
  ConsumerState<SelectAddressScreen> createState() =>
      _SelectAddressScreenState();
}

class _SelectAddressScreenState extends ConsumerState<SelectAddressScreen> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).findSelectIndex();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLtr = LocalStorage.getLangLtr();
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: KeyboardDismisser(
        child: Container(
          decoration: BoxDecoration(
            color: AppStyle.bgGrey.withOpacity(0.96),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
            ),
          ),
          width: double.infinity,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  8.verticalSpace,
                  Center(
                    child: Container(
                      height: 4.h,
                      width: 48.w,
                      decoration: BoxDecoration(
                        color: AppStyle.dragElement,
                        borderRadius: BorderRadius.all(Radius.circular(40.r)),
                      ),
                    ),
                  ),
                  24.verticalSpace,
                  TitleAndIcon(
                    title: AppHelpers.getTranslation(TrKeys.selectAddress),
                    paddingHorizontalSize: 0,
                    titleSize: 18,
                  ),
                  24.verticalSpace,
                  ListView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: ref
                            .watch(profileProvider)
                            .userData
                            ?.addresses
                            ?.length ??
                        0,
                    itemBuilder: (context, index) {
                      return SelectAddressItem(
                        onTap: () {
                          ref.read(profileProvider.notifier).change(index);
                        },
                        isActive:
                            ref.watch(profileProvider).selectAddress == index,
                        address: ref
                            .watch(profileProvider)
                            .userData
                            ?.addresses?[index],
                        update: () async {
                          await AppRoutes.I.pushViewMapRoute(context, address: ref
                                  .watch(profileProvider)
                                  .userData
                                  ?.addresses?[index],
                              indexAddress: index,);
                          if (context.mounted) {
                            ref.read(profileProvider.notifier).fetchUser(
                              context,
                              onSuccess: () {
                                ref
                                    .read(profileProvider.notifier)
                                    .findSelectIndex();
                              },
                            );
                          }
                        },
                      );
                    },
                  ),
                  16.verticalSpace,
                  CustomButton(
                    background: AppStyle.white,
                    title: AppHelpers.getTranslation(TrKeys.addAddress),
                    onPressed: () {
                      widget.addAddress.call();
                    },
                  ),
                  16.verticalSpace,
                  CustomButton(
                    title: AppHelpers.getTranslation(TrKeys.save),
                    onPressed: () {
                      ref.read(profileProvider.notifier).setActiveAddress(
                            index: ref.watch(profileProvider).selectAddress,
                            id: ref
                                .watch(profileProvider)
                                .userData
                                ?.addresses?[
                                    ref.watch(profileProvider).selectAddress]
                                .id,
                          );
                      LocalStorage.setAddressSelected(
                        AddressData(
                          title: ref
                                  .watch(profileProvider)
                                  .userData
                                  ?.addresses?[
                                      ref.watch(profileProvider).selectAddress]
                                  .title ??
                              "",
                          address: ref
                                  .watch(profileProvider)
                                  .userData
                                  ?.addresses?[
                                      ref.watch(profileProvider).selectAddress]
                                  .address
                                  ?.address ??
                              "",
                          location: LocationModel(
                            longitude: ref
                                .watch(profileProvider)
                                .userData
                                ?.addresses?[
                                    ref.watch(profileProvider).selectAddress]
                                .location
                                ?.last,
                            latitude: ref
                                .watch(profileProvider)
                                .userData
                                ?.addresses?[
                                    ref.watch(profileProvider).selectAddress]
                                .location
                                ?.first,
                          ),
                        ),
                      );
                      ref.read(homeProvider.notifier)
                        ..fetchBannerPage(
                          context,
                          RefreshController(),
                          isRefresh: true,
                        )
                        ..fetchAllShopsPage(
                          context,
                          RefreshController(),
                          isRefresh: true,
                        )
                        ..fetchShopPageRecommend(
                          context,
                          RefreshController(),
                          isRefresh: true,
                        )
                        ..fetchShopPage(
                          context,
                          RefreshController(),
                          isRefresh: true,
                        )
                        ..fetchStoriesPage(
                          context,
                          RefreshController(),
                          isRefresh: true,
                        )
                        ..fetchNewShopsPage(
                          context,
                          RefreshController(),
                          isRefresh: true,
                        )
                        ..fetchCategoriesPage(
                          context,
                          RefreshController(),
                          isRefresh: true,
                        )
                        ..setAddress();
                      ref.read(orderProvider.notifier).getCalculate(
                            context: context,
                            isLoading: false,
                            cartId: ref.read(shopOrderProvider).cart?.id ?? "",
                            long: LocalStorage.getAddressSelected()
                                    ?.location
                                    ?.longitude ??
                                AppConstants.demoLongitude,
                            lat: LocalStorage.getAddressSelected()
                                    ?.location
                                    ?.latitude ??
                                AppConstants.demoLatitude,
                            type: ref.read(orderProvider).tabIndex == 1
                                ? DeliveryTypeEnum.pickup
                                : DeliveryTypeEnum.delivery,
                          );
                      context.maybePop();
                    },
                  ),
                  32.verticalSpace,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
