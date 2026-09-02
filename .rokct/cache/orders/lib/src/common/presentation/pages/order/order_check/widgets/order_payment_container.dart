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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

class OrderPaymentContainer extends ConsumerWidget {
  final Widget icon;
  final String title;
  final bool isActive;
  final VoidCallback onTap;
  final bool isPayFast;

  const OrderPaymentContainer({
    super.key,
    required this.icon,
    required this.title,
    this.isActive = false,
    required this.onTap,
    this.isPayFast = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        onTap();

        // If this is PayFast and it's been selected, start preloading the WebView
        if (isPayFast && !isActive) {
          // We'll implement this logic in the payment selection flow
        }
      },
      child: Container(
        width: (MediaQuery.sizeOf(context).width - 42) / 2,
        height: 120.h,
        decoration: BoxDecoration(
          color: AppStyle.bgGrey,
          borderRadius: BorderRadius.all(Radius.circular(10.r)),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: isActive ? AppStyle.black : AppStyle.white,
                borderRadius: BorderRadius.all(Radius.circular(8.r)),
              ),
              padding: EdgeInsets.all(8.r),
              child: icon,
            ),
            8.verticalSpace,
            Text(
              AppHelpers.getTranslation(title),
              style: AppStyle.interSemi(size: 13, color: AppStyle.black),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
