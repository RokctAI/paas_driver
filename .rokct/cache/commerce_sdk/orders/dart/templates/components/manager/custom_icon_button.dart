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

import 'package:base_sdk/src/presentation/theme/app_style.dart';

class CustomIconButton extends StatelessWidget {
  final IconData? iconData;
  final Function()? onTap;
  final int size;

  const CustomIconButton({
    super.key,
    required this.iconData,
    this.onTap,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size.r,
        height: size.r,
        // Non-const: AppStyle.primary is an injectable getter in base_sdk.
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppStyle.primary,
        ),
        alignment: Alignment.center,
        child: Icon(
          iconData,
          size: 24.r,
          color: AppStyle.blackColor,
        ),
      ),
    );
  }
}
