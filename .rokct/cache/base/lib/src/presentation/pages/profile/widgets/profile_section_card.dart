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

/// Card wrapper for a profile section: optional caps group label above a
/// rounded surface holding the section's rows or content.
class ProfileSectionCard extends StatelessWidget {
  final String? title;
  final Widget child;

  const ProfileSectionCard({super.key, this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null && title!.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 4.r, bottom: 8.r),
            child: Text(
              title!.toUpperCase(),
              style: AppStyle.interSemi(
                size: 12.sp,
                color: AppStyle.textDarkSecondary,
              ),
            ),
          ),
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 16.r),
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: AppStyle.cardDark,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: child,
        ),
      ],
    );
  }
}
