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

import 'package:base_sdk/src/presentation/components/badges/ad_badge.dart';
import 'package:base_sdk/src/models/response/banners_paginate_response.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/presentation/components/custom_network_image.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

import 'package:marketplace_sdk/src/common/presentation/pages/home/home_four/banner_screen.dart';
//import 'package:base_sdk/src/services/tr_keys.dart';

class BannerItem extends StatelessWidget {
  final BannerData banner;
  final bool isAds;

  const BannerItem({super.key, required this.banner, this.isAds = false});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print("BUTTON TEXT DEBUG: BannerItem build for banner ID: ${banner.id}");
    }
    if (kDebugMode) {
      print(
        "BUTTON TEXT DEBUG: Button text in BannerItem build: '${banner.buttonText}'",
      );
    }

    return GestureDetector(
      onTap: () {
        if (kDebugMode) {
          print(
            "MODAL DEBUG: About to create BannerScreen with buttonText: '${banner.buttonText}'",
          );
        }
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
            buttonText: banner.buttonText,
            list: banner.shops ?? [],
          ),
          isDarkMode: false,
        );
      },
      child: Stack(
        children: [
          Container(
            margin: EdgeInsets.only(right: 6.r),
            width: MediaQuery.of(context).size.width - 46,
            decoration: BoxDecoration(
              color: AppStyle.white,
              borderRadius: BorderRadius.all(Radius.circular(15.r)),
            ),
            child: CustomNetworkImage(
              bgColor: AppStyle.white,
              url: banner.img ?? "",
              height: double.infinity,
              width: double.infinity,
              radius: 15.r,
            ),
          ),
          if (isAds) Positioned(right: 13.w, top: 10.h, child: const AdBadge()),
        ],
      ),
    );
  }
}
