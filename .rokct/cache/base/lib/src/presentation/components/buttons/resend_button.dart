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
import 'package:remixicon/remixicon.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';

class ResendButton extends StatelessWidget {
  final String title;
  final IconData iconData;
  final bool isTimeExpired;
  final bool isResending;
  final Function()? onPressed;

  const ResendButton({
    super.key,
    required this.title,
    this.iconData = Remix.refresh_line,
    this.isTimeExpired = false,
    this.isResending = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shadowColor: AppStyle.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: Size(97.r, 46.r),
        backgroundColor: AppStyle.black,
      ),
      onPressed: onPressed,
      child: isTimeExpired
          ? isResending
              ? SizedBox(
                  width: 10.r,
                  height: 10.r,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.r,
                    color: AppStyle.white,
                  ),
                )
              : Icon(iconData, color: AppStyle.white, size: 20)
          : Text(
              title,
              style: AppStyle.interNormal(size: 15, color: AppStyle.white),
            ),
    );
  }
}
