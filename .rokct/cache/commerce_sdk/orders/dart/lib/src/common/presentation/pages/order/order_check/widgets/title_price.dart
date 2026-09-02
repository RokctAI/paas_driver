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
import 'package:base_sdk/src/presentation/theme/theme.dart';

// ignore: must_be_immutable
class TitleAndPrice extends StatelessWidget {
  final String title;
  final String? rightTitle;
  final TextStyle textStyle;
  VoidCallback? onRightTap;

  TitleAndPrice({
    super.key,
    required this.title,
    this.rightTitle,
    this.onRightTap,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppStyle.interRegular(size: 16, color: AppStyle.black),
          ),
          GestureDetector(
            onTap: onRightTap ?? () {},
            child: Row(children: [Text(rightTitle ?? "", style: textStyle)]),
          ),
        ],
      ),
    );
  }
}
