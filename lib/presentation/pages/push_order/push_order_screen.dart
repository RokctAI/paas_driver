import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart' as intl;
import 'package:driver/application/providers.dart';
import '../../../infrastructure/models/data/order_detail.dart';
import 'package:driver/infrastructure/services/services.dart';
import 'package:driver/presentation/component/components.dart';
import 'package:driver/presentation/styles/style.dart';

class PushOrder extends ConsumerStatefulWidget {
  final OrderDetailData pushModel;
  final bool isActive;

  const PushOrder({super.key, required this.pushModel, required this.isActive});

  @override
  ConsumerState<PushOrder> createState() => _PushOrderState();
}

class _PushOrderState extends ConsumerState<PushOrder> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pushOrderProvider.notifier).startTimer();
    });
    super.initState();
  }

  @override
  void deactivate() {
    ref.read(pushOrderProvider.notifier).disposeTimer();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(pushOrderProvider, (previous, next) {
      if (next.isTimeOut) {
        Navigator.pop(context);
      }
    });
    final notifier = ref.read(pushOrderProvider.notifier);

    return Container(
      height: widget.isActive ? 500.h : 400.h,
      width: double.infinity,
      color: Style.transparent,
      child: Stack(
        children: [
          Positioned(
            bottom: 64.h,
            child: Container(
              height: widget.isActive ? 400.h : 300.h,
              width: MediaQuery.sizeOf(context).width - 32.w,
              decoration: BoxDecoration(
                color: Style.white,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  top: widget.isActive ? 84.h : 32.h,
                  left: 16.w,
                  right: 16.w,
                ),
                child: Column(
                  children: [
                    _orderAvatar(),
                    const Spacer(),
                    const Divider(color: Style.borderColor),
                    16.verticalSpace,
                    Row(
                      children: [
                        Icon(FlutterRemix.currency_line, size: 21.r),
                        10.horizontalSpace,
                        Text(
                          AppHelpers.numberFormat(
                            number: widget.pushModel.totalPrice ?? 0,
                          ),
                          style: Style.interSemi(size: 12.sp),
                        ),
                        const Spacer(),
                        Icon(FlutterRemix.takeaway_fill, size: 18.sp),
                        10.horizontalSpace,
                        Text(
                          AppHelpers.numberFormat(
                            number: widget.pushModel.deliveryFee ?? 0,
                          ),
                          style: Style.interSemi(size: 12.sp),
                        ),
                        const Spacer(),
                        Icon(FlutterRemix.bank_card_2_line, size: 18.sp),
                        10.horizontalSpace,
                        Text(
                          widget.pushModel.transaction?.paymentSystem?.tag ??
                              "",
                          style: Style.interSemi(size: 12.sp),
                        ),
                      ],
                    ),
                    16.verticalSpace,
                    const Divider(color: Style.borderColor),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            title: AppHelpers.getTranslation(TrKeys.skip),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            background: Style.transparent,
                            borderColor: Style.black,
                          ),
                        ),
                        14.horizontalSpace,
                        Expanded(
                          child: CustomButton(
                            isLoading: ref.watch(pushOrderProvider).isLoading,
                            title: widget.isActive
                                ? AppHelpers.getTranslation(TrKeys.accept)
                                : AppHelpers.getTranslation(
                                    TrKeys.orderInformation,
                                  ),
                            onPressed: () async {
                              if (widget.isActive) {
                                final ImageCropperMarker image =
                                    ImageCropperMarker();
                                notifier.changeLoading();
                                ref
                                    .read(homeProvider.notifier)
                                    .goMarket(
                                      context: context,
                                      orderId: widget.pushModel.id.toString(),
                                      order: widget.pushModel,
                                      setOrder: true,
                                      onSuccess: () async {
                                        notifier.changeLoading();
                                        Navigator.pop(context);
                                        ref
                                            .read(homeProvider.notifier)
                                            .getRoutingAll(
                                              // ignore: use_build_context_synchronously
                                              context: context,
                                              start: LatLng(
                                                LocalStorage.getAddressSelected()
                                                        ?.latitude ??
                                                    AppConstants.demoLatitude,
                                                LocalStorage.getAddressSelected()
                                                        ?.longitude ??
                                                    AppConstants.demoLongitude,
                                              ),
                                              end: LatLng(
                                                double.parse(
                                                  widget
                                                          .pushModel
                                                          .shop
                                                          ?.location
                                                          ?.latitude ??
                                                      "0",
                                                ),
                                                double.parse(
                                                  widget
                                                          .pushModel
                                                          .shop
                                                          ?.location
                                                          ?.longitude ??
                                                      "0",
                                                ),
                                              ),
                                              market: Marker(
                                                markerId: const MarkerId(
                                                  "Shop",
                                                ),
                                                position: LatLng(
                                                  double.parse(
                                                    widget
                                                            .pushModel
                                                            .shop
                                                            ?.location
                                                            ?.latitude ??
                                                        "0",
                                                  ),
                                                  double.parse(
                                                    widget
                                                            .pushModel
                                                            .shop
                                                            ?.location
                                                            ?.longitude ??
                                                        "0",
                                                  ),
                                                ),
                                                icon: await image
                                                    .resizeAndCircle(
                                                      widget
                                                              .pushModel
                                                              .shop
                                                              ?.logoImg ??
                                                          "",
                                                      120,
                                                    ),
                                              ),
                                            );
                                      },
                                    );
                              } else {
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    24.verticalSpace,
                  ],
                ),
              ),
            ),
          ),
          widget.isActive ? _timer(context) : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _timer(BuildContext context) {
    return Positioned(
      top: 0,
      right: (MediaQuery.sizeOf(context).width - 32.w) / 2 - 52.r,
      child: Container(
        padding: EdgeInsets.all(4.r),
        decoration: const BoxDecoration(
          color: Style.white,
          shape: BoxShape.circle,
        ),
        child: CircularPercentIndicator(
          radius: 48.r,
          lineWidth: 12.r,
          percent:
              double.parse(
                ref
                    .watch(pushOrderProvider)
                    .timerText
                    .substring(
                      0,
                      ref.watch(pushOrderProvider).timerText.indexOf(' '),
                    ),
              ) /
              AppHelpers.getAppDeliveryTime(),
          center: Text(
            ref.watch(pushOrderProvider).timerText,
            style: Style.interSemi(size: 18.sp),
          ),
          fillColor: Style.transparent,
          backgroundColor: Style.shimmerBase,
          progressColor: Style.progressColor,
          circularStrokeCap: CircularStrokeCap.round,
        ),
      ),
    );
  }

  Widget _orderAvatar() {
    return Column(
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
                  imageUrl: "${widget.pushModel.shop?.logoImg}",
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
                  widget.pushModel.shop?.translation?.title ?? "",
                  style: Style.interSemi(size: 14.sp, letterSpacing: -0.3),
                ),
                2.verticalSpace,
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Text(
                        '№ ${widget.pushModel.id}',
                        style: Style.interNormal(
                          size: 14.sp,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const VerticalDivider(),
                      Text(
                        intl.DateFormat("hh:mm").format(
                          DateTime.tryParse(
                                widget.pushModel.updatedAt ??
                                    DateTime.now().toString(),
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
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(left: 14.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4.r,
                height: 4.r,
                margin: EdgeInsets.only(bottom: 6.h, top: 6.h),
                decoration: const BoxDecoration(
                  color: Style.tabBarBorderColor,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 4.r,
                height: 4.r,
                margin: EdgeInsets.only(bottom: 10.h),
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
                  imageUrl: widget.pushModel.user?.img ?? "",
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
                  width: 100.w,
                  child: Text(
                    widget.pushModel.address?.address ?? "",
                    style: Style.interSemi(size: 14.sp, letterSpacing: -0.3),
                    maxLines: 1,
                  ),
                ),
                2.verticalSpace,
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Text(
                        widget.pushModel.user == null
                            ? AppHelpers.getTranslation(TrKeys.deletedUser)
                            : widget.pushModel.user?.firstname ?? "",
                        style: Style.interNormal(
                          size: 14.sp,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const VerticalDivider(),
                      Text(
                        widget.pushModel.user?.phone ?? "",
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
          ],
        ),
      ],
    );
  }
}
