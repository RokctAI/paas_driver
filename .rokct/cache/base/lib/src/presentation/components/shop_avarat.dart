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
import 'package:base_sdk/src/presentation/components/custom_network_image.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

// ignore: must_be_immutable
class ShopAvatar extends StatelessWidget {
  final String shopImage;
  final double size;
  final double padding;
  final double radius;
  Color bgColor;

  ShopAvatar({
    super.key,
    required this.shopImage,
    required this.size,
    required this.padding,
    this.bgColor = AppStyle.whiteWithOpacity,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.r,
      height: size.r,
      padding: EdgeInsets.all(padding.r),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: CustomNetworkImage(
        url: shopImage,
        height: size.r,
        width: size.r,
        radius: size.r / 2,
      ),
    );
  }
}
