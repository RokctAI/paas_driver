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

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';

class DoorToDoor extends StatelessWidget {
  const DoorToDoor({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.r),
      padding: EdgeInsets.all(30.r),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppStyle.doorColor,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppHelpers.getTranslation(TrKeys.doorToDoor),
            style: AppStyle.interSemi(size: 42),
          ),
          10.verticalSpace,
          Text(
            AppHelpers.getTranslation(TrKeys.yourPersonalDoor),
            style: AppStyle.interRegular(size: 16),
          ),
          20.verticalSpace,
          Image.asset("assets/images/door.png"),
          10.verticalSpace,
          CustomButton(
            title: AppHelpers.getTranslation(TrKeys.learnMore),
            onPressed: () {
              if (LocalStorage.getToken().isEmpty) {
                context.router.pushNamed('/login');
                return;
              }
              context.router.pushNamed('/parcel_page');
              return;
            },
            background: AppStyle.transparent,
            borderColor: AppStyle.black,
          ),
        ],
      ),
    );
  }
}
