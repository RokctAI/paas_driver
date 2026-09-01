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
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

class AdBadge extends StatelessWidget {
  const AdBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 22.h, // Adjust height as needed using ScreenUtil
          color: AppStyle.red, // Adjust color as needed
          padding: EdgeInsets.symmetric(
            horizontal: 5.w,
          ), // Adjust padding as needed using ScreenUtil
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppHelpers.getTranslation(
                  TrKeys.isAd,
                ), // Make sure AppHelpers is imported and accessible
                style: AppStyle.interNoSemi(size: 12, color: AppStyle.white),
              ),
              /* SizedBox(width: 2.w), // Adjust the width as needed using ScreenUtil
              Icon(
                Remix.advertisement_fill,
                color: AppStyle.white,
                size: 16.sp, // Adjust the icon size as needed using ScreenUtil
              ),*/
            ],
          ),
        ),
      ],
    );
  }
}
