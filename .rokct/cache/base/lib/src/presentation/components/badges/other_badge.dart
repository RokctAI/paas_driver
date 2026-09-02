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
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

import 'package:base_sdk/src/services/app_helpers.dart';

class AdBadge extends StatelessWidget {
  const AdBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: AppStyle.bottomNavigationBarColor.withOpacity(0.6),
        borderRadius: BorderRadius.all(Radius.circular(100.r)),
      ),
      child: Text(
        AppHelpers.getTranslation(TrKeys.isAd),
        style: AppStyle.interNormal(
          size: 12,
          letterSpacing: -0.3,
          color: AppStyle.white,
        ),
      ),
    );
  }
}
