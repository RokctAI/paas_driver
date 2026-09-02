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
import 'package:base_sdk/src/presentation/app_assets.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';

class NoDataInfo extends StatelessWidget {
  final String title;

  const NoDataInfo({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(Assets.imagesNotFound, width: 205.w, height: 206.h),
          Text(
            title,
            style: AppStyle.interRegular(
              size: 14,
              color: AppStyle.black,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
