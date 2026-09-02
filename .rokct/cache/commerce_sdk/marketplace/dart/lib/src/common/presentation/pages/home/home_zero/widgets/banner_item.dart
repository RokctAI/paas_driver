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
import 'package:base_sdk/src/models/response/banners_paginate_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/presentation/components/custom_network_image.dart';
import 'banner_screen.dart';

class BannerItem extends StatelessWidget {
  final BannerData banner;
  final bool isAds;

  const BannerItem({super.key, required this.banner, this.isAds = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Banner ids are Frappe docnames (hash strings); a banner without
        // one cannot be opened — skip instead of sending a sentinel.
        final String? bannerId = banner.id;
        if (bannerId == null) {
          debugPrint('==> banner tap skipped: banner has no id');
          return;
        }
        AppHelpers.showCustomModalBottomSheet(
          context: context,
          modal: BannerScreen(
            isAds: isAds,
            bannerId: bannerId,
            image: banner.img ?? "",
            desc: banner.translation?.description ?? "",
            list: banner.shops ?? [],
          ),
          isDarkMode: false,
        );
      },
      child: Container(
        margin: EdgeInsets.only(right: 6.r),
        width: MediaQuery.sizeOf(context).width - 46,
        decoration: BoxDecoration(
          color: AppStyle.white,
          borderRadius: BorderRadius.all(Radius.circular(8.r)),
        ),
        child: CustomNetworkImage(
          bgColor: AppStyle.white,
          url: banner.img ?? "",
          height: double.infinity,
          width: double.infinity,
          radius: 8.r,
        ),
      ),
    );
  }
}
