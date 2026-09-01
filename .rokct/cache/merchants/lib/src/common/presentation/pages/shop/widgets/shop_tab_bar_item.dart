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
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/presentation/components/buttons/animation_button_effect.dart';
import 'package:base_sdk/src/presentation/components/custom_network_image.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

class ShopTabBarItem extends StatelessWidget {
  final String title;
  final String image;
  final CategoryData? category;
  final bool isActive;
  final VoidCallback? onTap;

  const ShopTabBarItem({
    super.key,
    this.category,
    required this.isActive,
    this.onTap,
    required this.title,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onTap?.call();
      },
      child: AnimationButtonEffect(
        child: AnimatedContainer(
          height: 46.r,
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isActive ? AppStyle.primary : AppStyle.cardDark,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: [
              BoxShadow(
                color: AppStyle.white.withOpacity(0.07),
                spreadRadius: 0,
                blurRadius: 2,
                offset: const Offset(0, 1), // changes position of shadow
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 18.w),
          margin: EdgeInsets.only(right: 9.w, top: 24.h),
          child: Row(
            children: [
              if (category?.img?.isNotEmpty ?? false)
                Padding(
                  padding: EdgeInsets.only(right: 6.r),
                  child: CustomNetworkImage(
                    url: category?.img ?? image,
                    height: 42,
                    width: 42,
                    radius: 2,
                  ),
                ),
              Text(
                category?.translation?.title ?? title,
                style: AppStyle.interNormal(
                  size: 13,
                  color: isActive ? AppStyle.black : AppStyle.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
