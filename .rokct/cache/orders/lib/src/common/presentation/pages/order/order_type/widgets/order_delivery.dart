// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'package:auto_route/auto_route.dart';
import 'package:base_sdk/src/navigation/app_routes.dart';
import 'package:base_sdk/src/navigation/embedded_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:base_sdk/src/application/edit_profile/edit_profile_provider.dart';
import 'package:base_sdk/src/application/order/order_provider.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/app_validators.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/time_service.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/custom_checkbox.dart';
import 'package:base_sdk/src/presentation/components/text_fields/outline_bordered_text_field.dart';
// [refork] embed via EmbeddedWidgets
// [refork] removed host router import
import 'package:base_sdk/src/presentation/theme/theme.dart';
import 'package:orders_sdk/src/common/presentation/pages/order/order_check/widgets/time_delivery.dart';
import 'package:orders_sdk/src/common/presentation/pages/order/order_type/widgets/order_container.dart';
import 'package:base_sdk/src/presentation/components/sellect_address_screen.dart';

class OrderDelivery extends StatefulWidget {
  final ValueChanged<bool> onChange;
  final VoidCallback getLocation;
  final String shopId;

  const OrderDelivery({
    super.key,
    required this.onChange,
    required this.getLocation,
    required this.shopId,
  });

  @override
  State<OrderDelivery> createState() => _OrderDeliveryState();
}

class _OrderDeliveryState extends State<OrderDelivery> {
  late TextEditingController houseController;
  late TextEditingController floorController;
  late TextEditingController commentController;
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController userPhoneNumber;

  @override
  void initState() {
    houseController = TextEditingController(
      text: LocalStorage.getAddressInformation()?.house,
    );
    floorController = TextEditingController(
      text: LocalStorage.getAddressInformation()?.floor,
    );
    commentController = TextEditingController();
    nameController = TextEditingController();
    phoneController = TextEditingController();
    userPhoneNumber = TextEditingController(
      text: LocalStorage.getUser()?.phone,
    );
    super.initState();
  }

  @override
  void dispose() {
    houseController.dispose();
    floorController.dispose();
    commentController.dispose();
    nameController.dispose();
    phoneController.dispose();
    userPhoneNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 24.h),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Consumer(
          builder: (context, ref, child) {
            ref.listen(editProfileProvider, (previous, next) {
              if (next.isSuccess &&
                  (next.isSuccess != (previous?.isSuccess ?? false))) {
                userPhoneNumber.text = next.userData?.phone ?? "";
              }
            });
            return Column(
              children: [
                // Add the address tooltip with triangle pointer
                _buildAddressTooltip(context),
                10.verticalSpace,
                OrderContainer(
                  onTap: () async {
                    AppHelpers.showCustomModalBottomSheet(
                      context: context,
                      modal: SelectAddressScreen(
                        addAddress: () async {
                          await AppRoutes.I.pushViewMapRoute(context, shopId: widget.shopId);
                          widget.getLocation();
                        },
                      ),
                      isDarkMode: false,
                    );
                  },
                  icon: Padding(
                    padding: EdgeInsets.only(left: 4.w),
                    child: SvgPicture.asset(
                      "assets/svgs/adress.svg",
                      width: 20.r,
                      height: 20.r,
                    ),
                  ),
                  title: AppHelpers.getTranslation(TrKeys.deliveryAddress),
                  description:
                      (LocalStorage.getAddressSelected()?.title?.isEmpty ??
                              true)
                          ? LocalStorage.getAddressSelected()?.address ?? ''
                          : LocalStorage.getAddressSelected()?.title ?? "",
                ),
                10.verticalSpace,
                OrderContainer(
                  onTap: () {
                    AppHelpers.showCustomModalBottomSheet(
                      paddingTop: MediaQuery.paddingOf(context).top + 150.h,
                      context: context,
                      modal: const TimeDelivery(),
                      isDarkMode: false,
                      isDrag: true,
                      radius: 12,
                    );
                  },
                  icon: Icon(FlutterRemix.calendar_check_line, size: 24.r),
                  title: AppHelpers.getTranslation(TrKeys.timeDelivery),
                  description: ref.watch(orderProvider).selectDate == null
                      ? AppHelpers.getTranslation(
                          TrKeys.notWorkTodayAndTomorrow,
                        )
                      : "${TimeService.dateFormatMD(ref.watch(orderProvider).selectDate!)}  ${TimeService.timeFormatTime(ref.watch(orderProvider).selectTime.format(context))}",
                ),
                16.verticalSpace,
                OutlinedBorderTextField(
                  label: AppHelpers.getTranslation(TrKeys.house).toUpperCase(),
                  textController: houseController,
                  onChanged: (s) {
                    ref.read(orderProvider.notifier).setAddressInfo(house: s);
                  },
                ),
                12.verticalSpace,
                OutlinedBorderTextField(
                  label: AppHelpers.getTranslation(TrKeys.floor).toUpperCase(),
                  textController: floorController,
                  onChanged: (s) {
                    ref.read(orderProvider.notifier).setAddressInfo(floor: s);
                  },
                ),
                12.verticalSpace,
                OutlinedBorderTextField(
                  label: AppHelpers.getTranslation(
                    TrKeys.comment,
                  ).toUpperCase(),
                  textController: commentController,
                  onChanged: (s) {
                    ref.read(orderProvider.notifier).setAddressInfo(note: s);
                  },
                ),
                12.verticalSpace,
                OutlinedBorderTextField(
                  label: AppHelpers.getTranslation(
                    TrKeys.phoneNumber,
                  ).toUpperCase(),
                  textController: userPhoneNumber,
                  readOnly: true,
                  onTap: () {
                    AppHelpers.showCustomModalBottomSheet(
                      context: context,
                      modal: EmbeddedWidgets.I.phoneVerify(),
                      isDarkMode: false,
                      paddingTop: MediaQuery.paddingOf(context).top,
                    );
                  },
                ),
                12.verticalSpace,
                Row(
                  children: [
                    CustomCheckbox(
                      isActive: ref.watch(orderProvider).sendOtherUser,
                      onTap: () {
                        ref
                            .read(orderProvider.notifier)
                            .checkBox(!ref.watch(orderProvider).sendOtherUser);
                      },
                    ),
                    12.horizontalSpace,
                    Text(
                      AppHelpers.getTranslation(TrKeys.iWantToOrderForSomeone),
                    ),
                  ],
                ),
                if (ref.watch(orderProvider).sendOtherUser)
                  Column(
                    children: [
                      16.verticalSpace,
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedBorderTextField(
                              label: AppHelpers.getTranslation(
                                TrKeys.firstname,
                              ).toUpperCase(),
                              textController: nameController,
                              validation: AppValidators.isNotEmptyValidator,
                              onChanged: (s) {
                                ref
                                    .read(orderProvider.notifier)
                                    .setUser(username: s);
                              },
                            ),
                          ),
                          16.horizontalSpace,
                          Expanded(
                            child: OutlinedBorderTextField(
                              label: AppHelpers.getTranslation(
                                TrKeys.phoneNumber,
                              ).toUpperCase(),
                              textController: phoneController,
                              inputType: TextInputType.phone,
                              validation: AppValidators.isNotEmptyValidator,
                              onChanged: (s) {
                                ref
                                    .read(orderProvider.notifier)
                                    .setUser(phone: s);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAddressTooltip(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Main container
        Container(
          width: MediaQuery.of(context).size.width * 0.9,
          margin: EdgeInsets.only(
            bottom: 16.h,
          ), // Extra margin for the triangle pointer
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
          decoration: BoxDecoration(
            color: AppStyle.primary,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            AppHelpers.getTranslation(TrKeys.weAreDelivering),
            style: AppStyle.interRegular(size: 14, color: AppStyle.white),
            textAlign: TextAlign.center,
          ),
        ),

        // Triangle pointer (pointing down)
        Positioned(
          bottom: 8.h,
          right: 10.w,
          child: ClipPath(
            clipper: TriangleClipper(),
            child: Container(
              width: 16.h,
              height: 10.h,
              color: AppStyle.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// Custom clipper for creating the triangle pointer
class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width / 2, size.height);
    path.lineTo(0, 0);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(TriangleClipper oldClipper) => false;
}
