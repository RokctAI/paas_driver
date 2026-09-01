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
import 'package:remixicon/remixicon.dart';
import 'package:base_sdk/src/models/response/all_products_response.dart';

class OrganicTagBadge extends StatelessWidget {
  final Product product;
  final double? bottom;
  final String? workTime;
  final double? left;
  final double? right;
  final double? top;

  const OrganicTagBadge({
    super.key,
    required this.product,
    this.bottom,
    this.left,
    this.workTime,
    this.right,
    this.top,
  });

  @override
  Widget build(BuildContext context) {
    return product.vegetarian == true
        ? Positioned(
            bottom: bottom,
            left: left ?? 98.w,
            right: right,
            top: top ?? 20.h,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: const Icon(
                  Remix.leaf_fill,
                  color: Colors.green,
                  size: 15,
                ),
              ),
            ),
          )
        : const SizedBox.shrink();
  }
}
