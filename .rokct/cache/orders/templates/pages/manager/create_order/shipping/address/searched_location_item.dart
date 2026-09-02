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
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:osm_nominatim/osm_nominatim.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

class SearchedLocationItem extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;
  final bool isLast;

  const SearchedLocationItem({
    super.key,
    required this.place,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: AppStyle.white,
          child: InkWell(
            onTap: onTap,
            child: Container(
              height: 55.r,
              padding: REdgeInsets.symmetric(horizontal: 15),
              alignment: Alignment.center,
              child: Row(
                children: [
                  Icon(Remix.search_2_line, color: AppStyle.black, size: 20.r),
                  8.horizontalSpace,
                  Expanded(
                    child: Text(
                      place.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.k2d(
                        fontWeight: FontWeight.w500,
                        fontSize: 13.sp,
                        letterSpacing: -14 * 0.01,
                        color: AppStyle.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isLast)
          Divider(
            color: AppStyle.black.withOpacity(0.06),
            thickness: 1.r,
            height: 0.r,
          ),
      ],
    );
  }
}
