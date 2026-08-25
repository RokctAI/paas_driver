// Copyright (c) 2026 RokctAI
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

class CustomNetworkImage extends StatelessWidget {
  final String? url;
  final double? height;
  final double? width;
  final double radius;
  final Color? color; // New color parameter
  final Color bgColor;
  final BoxFit fit;
  final bool profile;
  final String? name;

  const CustomNetworkImage({
    super.key,
    required this.url,
    this.height,
    this.width,
    required this.radius,
    this.fit = BoxFit.cover,
    this.color, // New color parameter
    this.bgColor = AppStyle.mainBack,
    this.profile = false,
    this.name,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: color != null // Check if color is provided
          ? ColorFiltered(
              // Apply color filter if color is provided
              colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
              child: _buildImage(),
            )
          : _buildImage(), // Otherwise, show the original image
    );
  }

  Widget _buildImage() {
    return AppHelpers.checkIsSvg(url)
        ? SvgPicture.network(
            url ?? "",
            width: width,
            height: height,
            fit: BoxFit.cover,
            placeholderBuilder: (_) => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                color: AppStyle.shimmerBase,
              ),
            ),
          )
        : CachedNetworkImage(
            height: height,
            width: width,
            imageUrl: url ?? "",
            fit: fit,
            progressIndicatorBuilder: (context, url, progress) {
              return Container(
                height: height,
                width: width,
                decoration: BoxDecoration(color: AppStyle.shimmerBase),
              );
            },
            errorWidget: (context, url, error) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  color: bgColor,
                  image: profile
                      ? const DecorationImage(
                          image: AssetImage("assets/images/app_logo.png"),
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: profile
                    ? const SizedBox.shrink()
                    : const Icon(
                        Remix.image_line,
                        color: AppStyle.shimmerBaseDark,
                      ),
              );
            },
          );
  }
}
