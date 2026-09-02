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
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:base_sdk/src/models/data/story_data.dart';
import 'package:base_sdk/src/presentation/components/custom_network_image.dart';

class ShopBarItemThree extends StatelessWidget {
  final RefreshController controller;
  final StoryModel? story;
  final int index;

  const ShopBarItemThree({
    super.key,
    required this.story,
    required this.controller,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.router.pushNamed('/storyList?index=$index');
      },
      child: Container(
        margin: EdgeInsets.only(right: 9.r),
        width: 156.r,
        color: AppStyle.transparent,
        child: Stack(
          children: [
            CustomNetworkImage(
              url: story?.url ?? "",
              height: double.infinity,
              width: double.infinity,
              radius: 12.r,
            ),
            Positioned(
              child: Container(
                decoration: ShapeDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppStyle.black.withOpacity(0.2),
                      AppStyle.black.withOpacity(0.2),
                      AppStyle.black.withOpacity(0.2),
                      AppStyle.black.withOpacity(0.5),
                      AppStyle.black.withOpacity(0.7),
                    ],
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Center(
                child: Text(
                  story?.title ?? "",
                  style: AppStyle.interNoSemi(size: 14, color: AppStyle.white),
                  maxLines: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
