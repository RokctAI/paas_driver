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

import 'package:auto_route/auto_route.dart';
import 'package:base_sdk/src/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
// [refork] removed host router import
import 'package:base_sdk/src/presentation/theme/app_style.dart';

class InfoItem extends StatelessWidget {
  final int index;

  final bool isLarge;

  const InfoItem({super.key, required this.index, this.isLarge = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        AppRoutes.I.pushInfoRoute(context, index: index);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10.r),
        width: MediaQuery.sizeOf(context).width / 2 - 24.r,
        height: isLarge ? 230.r : 168.r,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          image: DecorationImage(
            image: AssetImage(AppConstants.infoImage[index]),
            fit: BoxFit.cover,
          ),
        ),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 18.r, bottom: 12.r, right: 24.r),
            child: Text(
              AppHelpers.getTranslation(AppConstants.infoTitle[index]),
              style: AppStyle.interNoSemi(size: 16, color: AppStyle.white),
            ),
          ),
        ),
      ),
    );
  }
}
