import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:driver/infrastructure/models/data/order_detail.dart';
import 'package:driver/infrastructure/services/services.dart';

import 'helper/shimmer.dart';
import '../styles/style.dart';
import 'package:intl/intl.dart' as intl;

import 'order_detail.dart';

class OrdersItem extends StatelessWidget {
  final OrderDetailData order;
  final bool isOrder;
  final bool isActiveButton;

  const OrdersItem({
    super.key,
    required this.order,
    required this.isOrder,
    this.isActiveButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        AppHelpers.showCustomModalBottomSheet(
          paddingTop: MediaQuery.paddingOf(context).top,
          context: context,
          radius: 12,
          modal: OrderDetail(
            isOrder: isOrder,
            order: order,
            isActiveButton: isActiveButton,
          ),
          isDarkMode: true,
        );
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: Style.white,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            style: Style.interSemi(
                              size: 14.sp,
                              letterSpacing: -0.3,
                            ),
                          ),
                          2.verticalSpace,
                          IntrinsicHeight(
                            child: Row(
                              children: [
                                Text(
                                  '№ ${order.id}',
                                  style: Style.interNormal(
                                    size: 14.sp,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const VerticalDivider(),
                                Text(
                                  intl.DateFormat("MMM dd HH:mm").format(
                                    DateTime.parse(
                                      order.createdAt ??
                                          DateTime.now().toString(),
                                    ).toLocal(),
                                  ),
                                  style: Style.interNormal(
                                    size: 14.sp,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        width: 36.r,
                        height: 36.r,
                        decoration: const BoxDecoration(
                          color: Style.greyColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(FlutterRemix.bank_card_2_line),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 14.w),
                    child: Column(
                      children: [
                        Container(
                          width: 4.r,
                          height: 4.r,
                          margin: EdgeInsets.only(bottom: 6.h, top: 2.h),
                          decoration: const BoxDecoration(
                            color: Style.tabBarBorderColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 4.r,
                          height: 4.r,
                          margin: EdgeInsets.only(bottom: 6.h),
                          decoration: const BoxDecoration(
                            color: Style.tabBarBorderColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            imageUrl: order.user?.img ?? "",
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
                          SizedBox(
                            width: MediaQuery.sizeOf(context).width - 124.w,
                            child: Text(
                              order.address?.address ?? "",
                              style: Style.interSemi(
                                size: 14.sp,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                          2.verticalSpace,
                          SizedBox(
                            width: MediaQuery.sizeOf(context).width - 124.w,
                            child: Row(
                              children: [
                                Expanded(
                                  child: AutoSizeText(
                                    order.user == null
                                        ? AppHelpers.getTranslation(
                                            TrKeys.deletedUser,
                                          )
                                        : order.user?.firstname ?? "",
                                    style: Style.interNormal(
                                      size: 14.sp,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    minFontSize: 14,
                                  ),
                                ),
                                SizedBox(
                                  height: 12.r,
                                  child: const VerticalDivider(
                                    width: 8,
                                    thickness: 1,
                                  ),
                                ),
                                Expanded(
                                  child: AutoSizeText(
                                    order.user?.phone ?? "",
                                    style: Style.interNormal(
                                      size: 14.sp,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    minFontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            16.verticalSpace,
            const Divider(color: Style.shimmerBase),
            8.verticalSpace,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Icon(FlutterRemix.currency_line, size: 21.r),
                  10.horizontalSpace,
                  Expanded(
                    child: AutoSizeText(
                      AppHelpers.numberFormat(number: order.totalPrice ?? 0),
                      style: Style.interSemi(size: 14.sp),
                      maxLines: 1,
                    ),
                  ),
                  Icon(FlutterRemix.takeaway_fill, size: 18.sp),
                  10.horizontalSpace,
                  Expanded(
                    child: AutoSizeText(
                      AppHelpers.numberFormat(number: order.deliveryFee ?? 0),
                      style: Style.interSemi(size: 14.sp),
                      maxLines: 1,
                    ),
                  ),
                  Container(
                    width: 36.r,
                    height: 36.r,
                    decoration: const BoxDecoration(
                      color: Style.greyColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(FlutterRemix.arrow_right_s_line),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
