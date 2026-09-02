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
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

class SearchResultText extends StatelessWidget {
  final String title;
  final VoidCallback canceled;
  final VoidCallback onTap;

  const SearchResultText({
    super.key,
    required this.title,
    required this.canceled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onTap,
                child: Row(
                  children: [
                    Icon(
                      FlutterRemix.search_2_line,
                      size: 20.r,
                      color: AppStyle.black,
                    ),
                    8.horizontalSpace,
                    Text(
                      title,
                      style: AppStyle.interNormal(
                        size: 14,
                        color: AppStyle.black,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    height: 20.r,
                    width: double.infinity,
                    color: AppStyle.transparent,
                  ),
                ),
              ),
              GestureDetector(
                onTap: canceled,
                child: Container(
                  color: AppStyle.transparent,
                  child: Padding(
                    padding: EdgeInsets.all(4.r),
                    child: Icon(
                      FlutterRemix.close_fill,
                      size: 20.r,
                      color: AppStyle.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
          10.verticalSpace,
          const Divider(color: AppStyle.borderColor),
        ],
      ),
    );
  }
}
