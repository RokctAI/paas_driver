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
import 'package:base_sdk/src/models/data/review_data.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

class ImagesOneList extends StatelessWidget {
  final List<Galleries>? list;
  final int? selectImageId;

  const ImagesOneList({
    super.key,
    required this.list,
    required this.selectImageId,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 6.r,
      width: MediaQuery.sizeOf(context).width,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: list
                    ?.map(
                      (e) => AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        margin: EdgeInsets.only(right: 6.r),
                        height: 6.r,
                        width: selectImageId == e.id ? 32.r : 8.r,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100.r),
                          color: selectImageId == e.id
                              ? AppStyle.black
                              : AppStyle.hintColor,
                        ),
                      ),
                    )
                    .toList() ??
                [],
          ),
        ),
      ),
    );
  }
}
