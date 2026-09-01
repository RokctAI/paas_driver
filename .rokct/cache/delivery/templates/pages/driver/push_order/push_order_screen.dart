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

import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart' as intl;

import 'package:delivery_sdk/src/driver/infrastructure/models/data/order_detail.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/marker_image_cropper.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:delivery_sdk/src/driver/application/home/home_provider.dart';
import 'package:delivery_sdk/src/driver/application/push_order/push_order_provider.dart';
import 'package:delivery_sdk/src/driver/infrastructure/services/courier_helpers.dart';
import 'package:delivery_sdk/src/driver/presentation/widgets/push_offer_decision.dart';

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
      color: AppStyle.transparent,
      child: Stack(
        children: [
          Positioned(
            bottom: 64.h,
            child: Container(
              height: widget.isActive ? 400.h : 300.h,
              width: MediaQuery.sizeOf(context).width - 32.w,
              // FRAME 49b - the dark fleet dress. This was the last
              // white card on the driver's decision path; the money
              // step it leads to (45d) is already on these tokens.
              decoration: BoxDecoration(
                color: AppStyle.cardDark,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppStyle.strokeDarkSubtle),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  top: widget.isActive ? 84.h : 32.h,
                  left: 16.w,
                  right: 16.w,
                ),
                child: Column(
                  children: [
                    // FRAME 49b - the one honest line. The ring reads
                    // like a reservation; it is the OFFER expiring, and
                    // the job is not held while it runs.
                    if (widget.isActive) ...[
                      const PushOfferTimerNote(),
                      12.verticalSpace,
                    ],
                    _orderLegs(),
                    const Spacer(),
                    Divider(color: AppStyle.strokeDark),
                    16.verticalSpace,
                    Row(
                      children: [
                        SvgPicture.asset(
                          "assets/svg/cutter.svg",
                          width: 18.r,
                          colorFilter: ColorFilter.mode(
                            AppStyle.textPrimary,
                            BlendMode.srcIn,
                          ),
                        ),
                        10.horizontalSpace,
                        Text(
                          AppHelpers.numberFormat(
                            number: widget.pushModel.totalPrice ?? 0,
                          ),
                          style: AppStyle.interSemi(size: 12.sp),
                        ),
                        const Spacer(),
                        Icon(
                          Remix.takeaway_fill,
                          size: 18.sp,
                          color: AppStyle.textPrimary,
                        ),
                        10.horizontalSpace,
                        Text(
                          AppHelpers.numberFormat(
                            number: widget.pushModel.deliveryFee ?? 0,
                          ),
                          style: AppStyle.interSemi(size: 12.sp),
                        ),
                        const Spacer(),
                        Icon(
                          Remix.bank_card_2_line,
                          size: 18.sp,
                          color: AppStyle.textPrimary,
                        ),
                        10.horizontalSpace,
                        Text(
                          widget.pushModel.transaction?.paymentSystem?.tag ??
                              "",
                          style: AppStyle.interSemi(size: 12.sp),
                        ),
                      ],
                    ),
                    // COD: make the amount the driver must physically
                    // collect unmissable before accepting the push order.
                    if ((widget.pushModel.transaction?.paymentSystem?.tag ??
                                '')
                            .toLowerCase() ==
                        'cash') ...[
                      12.verticalSpace,
                      Row(
                        children: [
                          Icon(Remix.money_dollar_circle_fill,
                              size: 20.sp, color: AppStyle.primary),
                          10.horizontalSpace,
                          Expanded(
                            child: Text(
                              "${AppHelpers.getTranslation(TrKeys.cashToCollect)}: ${AppHelpers.numberFormat(number: widget.pushModel.totalPrice ?? 0)}",
                              style: AppStyle.interBold(
                                size: 14.sp,
                                color: AppStyle.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    16.verticalSpace,
                    Divider(color: AppStyle.strokeDark),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            title: AppHelpers.getTranslation(TrKeys.skip),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            background: AppStyle.transparent,
                            borderColor: AppStyle.strokeDark,
                            textColor: AppStyle.textPrimary,
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
                                final ImageCropperForMarker image =
                                    ImageCropperForMarker();
                                notifier.changeLoading();
                                ref
                                    .read(homeProvider.notifier)
                                    .goMarket(
                                      context: context,
                                      orderId: widget.pushModel.id,
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

  /// FRAME 49b - the countdown, straddling the sheet edge.
  ///
  /// The placement is the shipped one (the ring is deliberately half
  /// over the panel's top edge); only the dress moved into
  /// [PushOfferCountdown]. The maths is untouched: the same
  /// `timerText` leading number over the same
  /// `CourierHelpers.getAppDeliveryTime()`.
  Widget _timer(BuildContext context) {
    final timerText = ref.watch(pushOrderProvider).timerText;
    return Positioned(
      top: 0,
      right: (MediaQuery.sizeOf(context).width - 32.w) / 2 - 52.r,
      child: PushOfferCountdown(
        percent: double.parse(
              timerText.substring(0, timerText.indexOf(' ')),
            ) /
            CourierHelpers.getAppDeliveryTime(),
        label: timerText,
      ),
    );
  }

  /// FRAME 49b - the two legs of the job, said out loud.
  ///
  /// The shipped layout already drew shop -> dots -> customer and never
  /// named either end. This maps the same payload fields onto
  /// [PushOfferLegs], which labels them PICKUP and DROP-OFF. No field
  /// is added and none is dropped.
  Widget _orderLegs() {
    return PushOfferLegs(
      pickup: PushOfferLeg(
        title: widget.pushModel.shop?.translation?.title ?? "",
        subtitle: '\u2116 ${widget.pushModel.id}',
        trailing: intl.DateFormat("hh:mm").format(
          DateTime.tryParse(
                widget.pushModel.updatedAt ?? DateTime.now().toString(),
              )?.toLocal() ??
              DateTime.now(),
        ),
        imageUrl: widget.pushModel.shop?.logoImg,
      ),
      dropOff: PushOfferLeg(
        title: widget.pushModel.address?.address ?? "",
        subtitle: widget.pushModel.user == null
            ? AppHelpers.getTranslation(TrKeys.deletedUser)
            : widget.pushModel.user?.firstname ?? "",
        trailing: widget.pushModel.user?.phone,
        imageUrl: widget.pushModel.user?.img,
      ),
    );
  }
}
