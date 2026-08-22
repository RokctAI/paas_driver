// Copyright (c) 2026 RokctAI
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
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:orders_sdk/src/common/application/parcel/parcel_notifier.dart';
import 'package:orders_sdk/src/common/application/parcel/parcel_state.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/buttons/animation_button_effect.dart';
import 'package:base_sdk/src/presentation/components/text_fields/outline_bordered_text_field.dart';
// [refork] removed host router import
import 'package:base_sdk/src/presentation/theme/app_style.dart';

import 'package:base_sdk/src/models/models.dart';
import 'package:orders_sdk/src/common/presentation/pages/parcel/widgets/custom_expanded.dart';

class SenderWidget extends StatelessWidget {
  final ParcelState state;
  final ParcelNotifier event;
  final TextEditingController username;
  final TextEditingController phone;
  final TextEditingController house;
  final TextEditingController flour;
  final TextEditingController comment;

  const SenderWidget({
    super.key,
    required this.state,
    required this.event,
    required this.username,
    required this.phone,
    required this.house,
    required this.flour,
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.expand)
          Padding(
            padding: EdgeInsets.only(bottom: 16.r),
            child: Text(
              AppHelpers.getTranslation(TrKeys.sender),
              style: AppStyle.interNoSemi(size: 16),
            ),
          ),
        InkWell(
          onTap: () async {
            final data = await AppRoutes.I.pushViewMapRoute(context, isShopLocation: true, isParcel: true);
            if (data.runtimeType == AddressNewModel) {
              if (context.mounted) {
                event.setFromAddress(
                  title: (data as AddressNewModel).address?.address,
                  location: LocationModel(
                    longitude: data.location?.last,
                    latitude: data.location?.first,
                  ),
                  context: context,
                );
              }
            }
          },
          child: AnimationButtonEffect(
            child: Container(
              decoration: BoxDecoration(
                color: AppStyle.bgGrey,
                borderRadius: BorderRadius.circular(10.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20.r, vertical: 16.r),
              child: Row(
                children: [
                  SvgPicture.asset("assets/svgs/pickUpFrom.svg"),
                  12.horizontalSpace,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (state.addressFrom != null)
                        Text(
                          AppHelpers.getTranslation(TrKeys.pickup),
                          style: AppStyle.interRegular(size: 12),
                        ),
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width / 2 - 20.r,
                        child: Text(
                          state.addressFrom ??
                              AppHelpers.getTranslation(TrKeys.pickup),
                          style: AppStyle.interSemi(size: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(FlutterRemix.arrow_right_s_line),
                ],
              ),
            ),
          ),
        ),
        ExpandedSection(
          expand: state.expand,
          child: Column(
            children: [
              24.verticalSpace,
              OutlinedBorderTextField(
                inputType: TextInputType.phone,
                label: AppHelpers.getTranslation(TrKeys.phoneNumber),
                textController: phone,
                validation: (s) {
                  if (s?.isNotEmpty ?? false) {
                    return null;
                  }
                  return AppHelpers.getTranslation(TrKeys.canNotBeEmpty);
                },
              ),
              16.verticalSpace,
              OutlinedBorderTextField(
                label: AppHelpers.getTranslation(TrKeys.fullName),
                textController: username,
                validation: (s) {
                  if (s?.isNotEmpty ?? false) {
                    return null;
                  }
                  return AppHelpers.getTranslation(TrKeys.canNotBeEmpty);
                },
              ),
              16.verticalSpace,
              OutlinedBorderTextField(
                label: AppHelpers.getTranslation(TrKeys.house),
                textController: house,
              ),
              16.verticalSpace,
              OutlinedBorderTextField(
                label: AppHelpers.getTranslation(TrKeys.floor),
                textController: flour,
              ),
              16.verticalSpace,
              OutlinedBorderTextField(
                label: AppHelpers.getTranslation(TrKeys.comment),
                textController: comment,
              ),
              24.verticalSpace,
            ],
          ),
        ),
      ],
    );
  }
}
