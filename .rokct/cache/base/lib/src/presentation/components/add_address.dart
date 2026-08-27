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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/application/home/home_provider.dart';
import 'package:base_sdk/src/models/data/address_old_data.dart';
import 'package:base_sdk/src/models/data/location.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
// [refork] removed host router import
import 'package:base_sdk/src/presentation/theme/app_style.dart';

class AddAddress extends StatelessWidget {
  const AddAddress({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppHelpers.getTranslation(TrKeys.agreeLocation),
          style: AppStyle.interSemi(size: 16.sp),
          textAlign: TextAlign.center,
        ),
        24.verticalSpace,
        Row(
          children: [
            Expanded(
              child: CustomButton(
                title: AppHelpers.getTranslation(TrKeys.cancel),
                borderColor: AppStyle.black,
                background: AppStyle.transparent,
                onPressed: () {
                  Navigator.pop(context);
                  AppRoutes.I.pushViewMapRoute(context, isPop: true);
                },
              ),
            ),
            24.horizontalSpace,
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  return CustomButton(
                    title: AppHelpers.getTranslation(TrKeys.yes),
                    onPressed: () {
                      Navigator.pop(context);
                      LocalStorage.setAddressSelected(
                        AddressData(
                          title: AppHelpers.getAppAddressName(),
                          location: LocationModel(
                            longitude: (AppHelpers.getInitialLongitude() ??
                                AppConstants.demoLongitude),
                            latitude: (AppHelpers.getInitialLatitude() ??
                                AppConstants.demoLatitude),
                          ),
                        ),
                      );
                      ref.read(homeProvider.notifier).setAddress();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
