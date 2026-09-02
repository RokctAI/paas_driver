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

import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';

class ShopAvatar extends StatelessWidget {
  final double size;
  final double padding;
  final double radius;
  final Color bgColor;
  final String? imageUrl;
  final String? path;

  const ShopAvatar({
    super.key,
    required this.size,
    required this.padding,
    this.bgColor = const Color(0x06000000),
    this.radius = 10,
    this.imageUrl,
    this.path,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          width: size.r,
          height: size.r,
          color: bgColor,
          padding: EdgeInsets.all(padding.r),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size.r / 2),
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: '$imageUrl',
                    fit: BoxFit.cover,
                    progressIndicatorBuilder: (context, url, progress) {
                      return Shimmer.fromColors(
                        baseColor: AppStyle.shimmerBase,
                        highlightColor: AppStyle.shimmerHighlight,
                        child: Container(
                          height: size.r,
                          decoration: BoxDecoration(
                            color: AppStyle.white,
                            borderRadius: BorderRadius.circular(size.r / 2),
                          ),
                        ),
                      );
                    },
                    errorWidget: (context, url, error) {
                      return Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppStyle.bgGrey,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Remix.image_line,
                          color: AppStyle.black,
                        ),
                      );
                    },
                  )
                : path != null
                ? Image.file(
                    File(path!),
                    width: size.r,
                    height: size.r,
                    fit: BoxFit.cover,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
