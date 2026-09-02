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
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

class CongratsPage extends StatelessWidget {
  final bool isOrder;
  final VoidCallback? onTap;

  const CongratsPage({super.key, this.isOrder = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              16.verticalSpace,
              Text(
                AppHelpers.getTranslation(TrKeys.checkout),
                style: AppStyle.interSemi(color: AppStyle.textGrey, size: 22),
              ),
              42.verticalSpace,
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.r),
                child: Image.asset("assets/images/order_success.png"),
              ),
              6.verticalSpace,
              if (isOrder)
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        AppHelpers.getTranslation(TrKeys.congrats),
                        style: AppStyle.interBold(
                          color: AppStyle.textGrey,
                          size: 20,
                        ),
                      ),
                      6.verticalSpace,
                      Text(
                        AppHelpers.getTranslation(TrKeys.thankYouPurchase),
                        style: AppStyle.interNormal(
                          color: AppStyle.textGrey,
                          size: 14,
                        ),
                      ),
                      Text(
                        AppHelpers.getTranslation(TrKeys.yourOrderShipping),
                        style: AppStyle.interNormal(
                          color: AppStyle.textGrey,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              if (!isOrder)
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        AppHelpers.getTranslation(TrKeys.congrats),
                        style: AppStyle.interBold(
                          color: AppStyle.textGrey,
                          size: 20,
                        ),
                      ),
                      6.verticalSpace,
                      Text(
                        AppHelpers.getTranslation(TrKeys.paymentSuccessful),
                        style: AppStyle.interNormal(
                          color: AppStyle.textGrey,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.r),
        child: SizedBox(
          height: 60.r,
          width: double.infinity,
          child: CustomButton(
            title: AppHelpers.getTranslation(
              isOrder ? TrKeys.returnHome : TrKeys.ok,
            ),
            background: AppStyle.primary,
            textColor: AppStyle.white,
            onPressed: () {
              if (onTap != null) {
                onTap!();
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
