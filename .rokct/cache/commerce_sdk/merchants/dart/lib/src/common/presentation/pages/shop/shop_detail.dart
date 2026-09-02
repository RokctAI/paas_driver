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
import 'package:base_sdk/src/navigation/embedded_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:base_sdk/src/application/shop/shop_provider.dart';
import 'package:base_sdk/src/models/data/shop_data.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
// [refork] embed via EmbeddedWidgets
import 'package:base_sdk/src/presentation/theme/app_style.dart';

import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/presentation/components/buttons/pop_button.dart';

@RoutePage()
class ShopDetailPage extends ConsumerStatefulWidget {
  final ShopData shop;
  final String workTime;

  const ShopDetailPage({super.key, required this.shop, required this.workTime});

  @override
  ConsumerState<ShopDetailPage> createState() => _ShopDetailPageState();
}

class _ShopDetailPageState extends ConsumerState<ShopDetailPage> {
  @override
  initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shopProvider.notifier)
        ..getMarker()
        ..getRoutingAll(
          context: context,
          start: LatLng(
            widget.shop.location?.latitude ?? AppConstants.demoLatitude,
            widget.shop.location?.longitude ?? AppConstants.demoLongitude,
          ),
          end: LatLng(
            LocalStorage.getAddressSelected()?.location?.latitude ??
                AppConstants.demoLatitude,
            LocalStorage.getAddressSelected()?.location?.longitude ??
                AppConstants.demoLongitude,
          ),
        );
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLtr = LocalStorage.getLangLtr();
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppStyle.bgGrey,
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: 32.r),
          child: Column(
            children: [
              EmbeddedWidgets.I.orderMap(
                markers: ref.watch(shopProvider).shopMarkers,
                latLng: LatLng(
                  widget.shop.location?.latitude ?? AppConstants.demoLatitude,
                  widget.shop.location?.longitude ?? AppConstants.demoLongitude,
                ),
                polylineCoordinates:
                    ref.watch(shopProvider).polylineCoordinates,
                isLoading: ref.watch(shopProvider).isMapLoading,
              ),
              16.verticalSpace,
              Padding(
                padding: EdgeInsetsDirectional.only(start: 16.w),
                child: Text(
                  "${widget.shop.translation?.title ?? ""}(${widget.shop.translation?.address ?? ""})",
                  style: AppStyle.interBold(),
                ),
              ),
              16.verticalSpace,
              Padding(
                padding: EdgeInsetsDirectional.only(start: 16.w),
                child: SizedBox(
                  height: 18.h,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.shop.tags?.length ?? 0,
                        itemBuilder: (BuildContext context, int index) {
                          return Text(
                            "${widget.shop.tags?[index].translation?.title ?? ""} • ",
                            style: AppStyle.interNormal(
                              color: AppStyle.textGrey,
                            ),
                          );
                        },
                      ),
                      Text(
                        LocalStorage.getSelectedCurrency()?.symbol ?? "",
                        style: AppStyle.interRegular(
                          color: AppStyle.textGrey,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Divider(color: AppStyle.hintColor, thickness: 1.5.w),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.r),
                child: InkWell(
                  onTap: () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text: widget.shop.translation?.address ?? "",
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.place_rounded),
                      24.horizontalSpace,
                      Expanded(
                        child: Text(widget.shop.translation?.address ?? ""),
                      ),
                      const Spacer(),
                      const Icon(
                        Remix.file_copy_fill,
                        color: AppStyle.textGrey,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                child: const Divider(color: AppStyle.hintColor),
              ),
              Consumer(
                builder: (context, ref, child) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.r),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Remix.time_fill),
                            24.horizontalSpace,
                            Text(
                              "${AppHelpers.getTranslation(TrKeys.openUntil)} ${widget.workTime}",
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                ref.watch(shopProvider).showWeekTime
                                    ? Remix.subtract_fill
                                    : Remix.add_fill,
                                color: AppStyle.textGrey,
                              ),
                              onPressed: () {
                                ref.read(shopProvider.notifier).showWeekTime();
                              },
                            ),
                          ],
                        ),
                        ref.watch(shopProvider).showWeekTime
                            ? ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                padding: EdgeInsets.only(left: 48.r),
                                itemCount:
                                    widget.shop.shopWorkingDays?.length ?? 0,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 6.r,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppHelpers.getTranslation(
                                            widget.shop.shopWorkingDays?[index]
                                                    .day ??
                                                "",
                                          ).toUpperCase(),
                                          style: AppStyle.interNoSemi(size: 14),
                                        ),
                                        2.verticalSpace,
                                        Text(
                                          "${widget.shop.shopWorkingDays?[index].from} - ${widget.shop.shopWorkingDays?[index].to}",
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
                  );
                },
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                child: const Divider(color: AppStyle.hintColor),
              ),
              if (ref.watch(shopProvider).branches?.isNotEmpty ?? false)
                _branches(),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Divider(color: AppStyle.hintColor, thickness: 1.5.w),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.r),
                child: Row(
                  children: [
                    const Icon(Remix.star_fill),
                    24.horizontalSpace,
                    Text(
                      "${widget.shop.avgRate} (${widget.shop.rateCount}+ ${AppHelpers.getTranslation(TrKeys.ratings)})",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: Padding(
          padding: EdgeInsets.only(left: 16.w),
          child: const PopButton(),
        ),
      ),
    );
  }

  Consumer _branches() {
    return Consumer(
      builder: (context, ref, child) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.r),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Remix.store_3_fill),
                  24.horizontalSpace,
                  Text(AppHelpers.getTranslation(TrKeys.branches)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      ref.watch(shopProvider).showBranch
                          ? Remix.subtract_fill
                          : Remix.add_fill,
                      color: AppStyle.textGrey,
                    ),
                    onPressed: () {
                      ref.read(shopProvider.notifier).showBranch();
                    },
                  ),
                ],
              ),
              ref.watch(shopProvider).showBranch
                  ? ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: EdgeInsets.only(left: 48.r),
                      itemCount: ref.watch(shopProvider).branches?.length ?? 0,
                      itemBuilder: (context, index) {
                        final branches =
                            ref.watch(shopProvider).branches?[index];
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 6.r),
                          child: Row(
                            children: [
                              SizedBox(
                                width: MediaQuery.sizeOf(context).width - 150.r,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${branches?.translation?.title ?? ""} : ",
                                      style: AppStyle.interNoSemi(size: 14),
                                    ),
                                    2.verticalSpace,
                                    Text(branches?.address?.address ?? ""),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  ref.read(shopProvider.notifier)
                                    ..changeMap(
                                      shopLocation: LatLng(
                                        branches?.location?.latitude ?? 0,
                                        branches?.location?.longitude ?? 0,
                                      ),
                                    )
                                    ..getRoutingAll(
                                      context: context,
                                      start: LatLng(
                                        branches?.location?.latitude ?? 0,
                                        branches?.location?.longitude ?? 0,
                                      ),
                                      end: LatLng(
                                        LocalStorage.getAddressSelected()
                                                ?.location
                                                ?.latitude ??
                                            AppConstants.demoLatitude,
                                        LocalStorage.getAddressSelected()
                                                ?.location
                                                ?.longitude ??
                                            AppConstants.demoLongitude,
                                      ),
                                    );
                                },
                                icon: const Icon(Remix.road_map_line),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        );
      },
    );
  }
}
