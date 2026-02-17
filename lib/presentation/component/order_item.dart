import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:driver/application/order/all_order/order_provider.dart';
import 'package:driver/infrastructure/models/data/order_detail.dart';
import 'package:driver/presentation/component/components.dart';
import 'package:driver/presentation/component/maps_list.dart';

import '../../application/home/home_provider.dart';
import '../../infrastructure/services/app_helpers.dart';
import '../../infrastructure/services/tr_keys.dart';
import '../styles/style.dart';
import 'package:intl/intl.dart' as intl;

class OrderItem extends StatelessWidget {
  final OrderDetailData order;
  final bool isDeliveryShop;
  final bool isDeliveryClient;
  final bool isSetCurrentOrder;

  const OrderItem({
    super.key,
    required this.order,
    this.isDeliveryShop = false,
    this.isDeliveryClient = false,
    this.isSetCurrentOrder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _orderAvatar(context),
        16.verticalSpace,
        Container(
          decoration: BoxDecoration(
            color: Style.white,
            borderRadius: BorderRadius.circular(10.r),
          ),
          padding: EdgeInsets.all(16.r),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppHelpers.getTranslation(TrKeys.restaurantHome),
                    style: Style.interNormal(
                      size: 12.sp,
                      color: Style.black,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    "${(order.distance ?? 0).toString()} ${AppHelpers.getTranslation(TrKeys.km)}",
                    style: Style.interSemi(
                      size: 14.sp,
                      color: Style.black,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              order.address?.house != "null"
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppHelpers.getTranslation(TrKeys.home),
                          style: Style.interNormal(
                            size: 12.sp,
                            color: Style.black,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          order.address?.house ?? "",
                          style: Style.interSemi(
                            size: 14.sp,
                            color: Style.black,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
              order.address?.office != "null"
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppHelpers.getTranslation(TrKeys.entr),
                          style: Style.interNormal(
                            size: 12.sp,
                            color: Style.black,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          order.address?.office ?? "",
                          style: Style.interSemi(
                            size: 14.sp,
                            color: Style.black,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
              order.address?.floor != "null"
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppHelpers.getTranslation(TrKeys.apart),
                          style: Style.interNormal(
                            size: 12.sp,
                            color: Style.black,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          order.address?.floor ?? "",
                          style: Style.interSemi(
                            size: 14.sp,
                            color: Style.black,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
        10.verticalSpace,
        Container(
          decoration: BoxDecoration(
            color: Style.white,
            borderRadius: BorderRadius.circular(10.r),
          ),
          padding: EdgeInsets.all(16.r),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppHelpers.getTranslation(TrKeys.askThisCodeFromCustomer),
                    style: Style.interNormal(
                      size: 12.sp,
                      color: Style.black,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    (order.otp ?? 0).toString(),
                    style: Style.interSemi(
                      size: 14.sp,
                      color: Style.black,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              order.address?.house != "null"
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppHelpers.getTranslation(TrKeys.home),
                          style: Style.interNormal(
                            size: 12.sp,
                            color: Style.black,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          order.address?.house ?? "",
                          style: Style.interSemi(
                            size: 14.sp,
                            color: Style.black,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
              order.address?.office != "null"
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppHelpers.getTranslation(TrKeys.entr),
                          style: Style.interNormal(
                            size: 12.sp,
                            color: Style.black,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          order.address?.office ?? "",
                          style: Style.interSemi(
                            size: 14.sp,
                            color: Style.black,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
              order.address?.floor != "null"
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppHelpers.getTranslation(TrKeys.apart),
                          style: Style.interNormal(
                            size: 12.sp,
                            color: Style.black,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          order.address?.floor ?? "",
                          style: Style.interSemi(
                            size: 14.sp,
                            color: Style.black,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
        10.verticalSpace,
        order.note != null ? _reminder() : const SizedBox.shrink(),
        10.verticalSpace,
        Container(
          decoration: BoxDecoration(
            color: Style.white,
            borderRadius: BorderRadius.circular(10.r),
          ),
          padding: EdgeInsets.all(16.r),
          child: Row(
            children: [
              Icon(FlutterRemix.currency_line, size: 21.r),
              10.horizontalSpace,
              Text(
                AppHelpers.numberFormat(number: order.totalPrice ?? 0),
                style: Style.interSemi(size: 12.sp),
              ),
              const Spacer(),
              Icon(FlutterRemix.takeaway_fill, size: 18.sp),
              10.horizontalSpace,
              Text(
                AppHelpers.numberFormat(number: order.deliveryFee ?? 0),
                style: Style.interSemi(size: 12.sp),
              ),
              const Spacer(),
              Icon(FlutterRemix.bank_card_2_line, size: 18.sp),
              10.horizontalSpace,
              Text(
                order.transaction?.paymentSystem?.tag ?? "",
                style: Style.interSemi(size: 12.sp),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _orderAvatar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 32.r,
              width: 32.r,
              decoration: const BoxDecoration(
                color: Style.white,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: "${order.shop?.logoImg}",
                  fit: BoxFit.cover,
                  progressIndicatorBuilder: (context, url, progress) {
                    return ImageShimmer(isCircle: true, size: 32.r);
                  },
                  errorWidget: (context, url, error) {
                    return Container(
                      height: 32.r,
                      width: 32.r,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Style.greyColor,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        FlutterRemix.image_line,
                        color: Style.black,
                      ),
                    );
                  },
                ),
              ),
            ),
            16.horizontalSpace,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.shop?.translation?.title ?? "",
                  style: Style.interSemi(size: 14.sp, letterSpacing: -0.3),
                ),
                2.verticalSpace,
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Text(
                        "№ ${order.id}",
                        style: Style.interNormal(
                          size: 14.sp,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const VerticalDivider(),
                      Text(
                        intl.DateFormat("HH:mm").format(
                          DateTime.tryParse(
                                order.updatedAt ?? DateTime.now().toString(),
                              )?.toLocal() ??
                              DateTime.now(),
                        ),
                        style: Style.interNormal(
                          size: 14.sp,
                          letterSpacing: -0.3,
                        ),
                      ),
                      16.horizontalSpace,
                      Icon(FlutterRemix.building_fill, size: 18.r),
                      IconButton(
                        padding: EdgeInsets.symmetric(horizontal: 6.w),
                        onPressed: () async {
                          AppHelpers.showCustomModalBottomSheet(
                            context: context,
                            modal: MapsList(
                              location: Coords(
                                double.tryParse(
                                      order.shop?.location?.latitude ?? "0",
                                    ) ??
                                    0,
                                double.tryParse(
                                      order.shop?.location?.longitude ?? "0",
                                    ) ??
                                    0,
                              ),
                              title: "Shop",
                            ),
                            isDarkMode: false,
                          );
                        },
                        icon: Icon(FlutterRemix.map_2_fill, size: 18.r),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            isDeliveryShop
                ? Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final Uri launchUri = Uri(
                            scheme: 'tel',
                            path: order.shop?.phone ?? "",
                          );
                          await launchUrl(launchUri);
                        },
                        child: Container(
                          height: 38.r,
                          width: 38.r,
                          decoration: const BoxDecoration(
                            color: Style.black,
                            shape: BoxShape.circle,
                          ),
                          margin: EdgeInsets.all(4.r),
                          child: Icon(
                            FlutterRemix.phone_fill,
                            color: Style.white,
                            size: 20.r,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final Uri launchUri = Uri(
                            scheme: 'sms',
                            path: order.shop?.phone ?? "",
                          );
                          await launchUrl(launchUri);
                        },
                        child: Container(
                          height: 38.r,
                          width: 38.r,
                          decoration: const BoxDecoration(
                            color: Style.black,
                            shape: BoxShape.circle,
                          ),
                          margin: EdgeInsets.all(4.r),
                          child: Icon(
                            FlutterRemix.chat_1_fill,
                            color: Style.white,
                            size: 20.r,
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
            isSetCurrentOrder
                ? Consumer(
                    builder: (context, ref, child) {
                      return CustomToggle(
                        isOrder: true,
                        isOnline: order.current ?? false,
                        onChange: (bool value) {
                          if (value) {
                            ref.read(orderProvider.notifier).setCurrentOrder(
                              context,
                              order.id ?? 0,
                              () {
                                ref
                                    .read(homeProvider.notifier)
                                    .fetchCurrentOrder(context);
                              },
                            );
                          }
                        },
                      );
                    },
                  )
                : const SizedBox.shrink(),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(left: 14.sp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4.r,
                height: 4.r,
                margin: EdgeInsets.only(bottom: 6.h),
                decoration: const BoxDecoration(
                  color: Style.toggleColor,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 4.r,
                height: 4.r,
                margin: EdgeInsets.only(bottom: 4.h),
                decoration: const BoxDecoration(
                  color: Style.toggleColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 32.r,
              width: 32.r,
              decoration: const BoxDecoration(
                color: Style.white,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: "${order.user?.img}",
                  fit: BoxFit.cover,
                  progressIndicatorBuilder: (context, url, progress) {
                    return ImageShimmer(isCircle: true, size: 32.r);
                  },
                  errorWidget: (context, url, error) {
                    return Container(
                      height: 32.r,
                      width: 32.r,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Style.greyColor,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        FlutterRemix.image_line,
                        color: Style.black,
                      ),
                    );
                  },
                ),
              ),
            ),
            16.horizontalSpace,
            SizedBox(
              width: MediaQuery.sizeOf(context).width - 180.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: MediaQuery.sizeOf(context).width - 190.w,
                    child: Text(
                      order.address?.address ?? "",
                      style: Style.interSemi(size: 14.sp, letterSpacing: -0.3),
                      maxLines: 1,
                    ),
                  ),
                  2.verticalSpace,
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.user == null
                                ? AppHelpers.getTranslation(TrKeys.deletedUser)
                                : order.user?.firstname ?? "",
                            style: Style.interNormal(
                              size: 12.sp,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const VerticalDivider(),
                        Text(
                          order.user?.phone ?? "",
                          style: Style.interNormal(
                            size: 12.sp,
                            letterSpacing: -0.3,
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.symmetric(horizontal: 6.w),
                          onPressed: () {
                            AppHelpers.showCustomModalBottomSheet(
                              context: context,
                              modal: MapsList(
                                location: Coords(
                                  double.tryParse(
                                        order.location?.latitude ?? "0",
                                      ) ??
                                      0,
                                  double.tryParse(
                                        order.location?.longitude ?? "0",
                                      ) ??
                                      0,
                                ),
                                title: "User",
                              ),
                              isDarkMode: false,
                            );
                          },
                          icon: Icon(FlutterRemix.map_2_fill, size: 18.r),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            isDeliveryClient
                ? Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final Uri launchUri = Uri(
                            scheme: 'tel',
                            path: order.user?.phone ?? "",
                          );
                          await launchUrl(launchUri);
                        },
                        child: Container(
                          height: 38.r,
                          width: 38.r,
                          decoration: const BoxDecoration(
                            color: Style.black,
                            shape: BoxShape.circle,
                          ),
                          margin: EdgeInsets.all(4.r),
                          child: Icon(
                            FlutterRemix.phone_fill,
                            color: Style.white,
                            size: 20.r,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final Uri launchUri = Uri(
                            scheme: 'sms',
                            path: order.user?.phone ?? "",
                          );
                          await launchUrl(launchUri);
                        },
                        child: Container(
                          height: 38.r,
                          width: 38.r,
                          decoration: const BoxDecoration(
                            color: Style.black,
                            shape: BoxShape.circle,
                          ),
                          margin: EdgeInsets.all(4.r),
                          child: Icon(
                            FlutterRemix.chat_1_fill,
                            color: Style.white,
                            size: 20.r,
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ],
    );
  }

  Widget _reminder() {
    return Container(
      decoration: BoxDecoration(
        color: Style.white,
        borderRadius: BorderRadius.circular(10.r),
      ),
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(FlutterRemix.chat_1_fill),
          12.horizontalSpace,
          Expanded(
            child: Text(
              order.note ?? "",
              style: Style.interRegular(size: 13.sp, color: Style.black),
            ),
          ),
        ],
      ),
    );
  }
}
