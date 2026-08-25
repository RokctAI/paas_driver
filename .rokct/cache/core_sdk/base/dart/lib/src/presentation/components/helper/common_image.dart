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


import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/presentation/components/buttons/animation_button_effect2.dart';

class CommonImage extends StatelessWidget {
  final String? url;
  final File? fileImage;
  final double? width;
  final String? preview;
  final double? height;
  final double radius;
  final double errorRadius;
  final Color? errorBackground;
  final BoxFit? fit;
  final String? name;
  final String? title;
  final VoidCallback? onDelete;

  const CommonImage({
    super.key,
    this.url,
    this.width,
    this.height,
    this.radius = 10,
    this.errorRadius = 10,
    this.errorBackground,
    this.fit,
    this.fileImage,
    this.preview,
    this.name,
    this.title,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
        borderRadius: BorderRadius.circular(radius.r),
        child: preview != null
            ? Stack(
                children: [
                  CachedNetworkImage(
                    height: height?.r,
                    width: width?.r,
                    imageUrl: preview ?? "",
                    fit: fit,
                    progressIndicatorBuilder: (context, url, progress) {
                      return Container(
                        height: height?.r,
                        width: width?.r,
                        decoration: BoxDecoration(
                          color: AppStyle.shimmerBase,
                        ),
                        child: (width ?? 0) > 58
                            ? Center(
                                child: Text(
                                  AppHelpers.getTranslation(
                                      AppHelpers.getAppName() ?? ''),
                                  style: AppStyle.interNormal(
                                      color: AppStyle.textGrey, size: 12),
                                ),
                              )
                            : const SizedBox.shrink(),
                      );
                    },
                    errorWidget: (context, url, error) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(radius.r),
                          color: name == null
                              ? AppStyle.shimmerBase
                              : AppStyle.primary,
                        ),
                        alignment: Alignment.center,
                        child: name == null
                            ? const Icon(Remix.file_unknow_line)
                            : Text(
                                name?.substring(0, 1) ?? "",
                                style: AppStyle.interNormal(
                                  color: AppStyle.white,
                                  size: (height ?? 0) / 2.5,
                                ),
                              ),
                      );
                    },
                  ),
                  Positioned.fill(
                    child: Center(
                      child: ButtonEffectAnimation(
                        onTap: () {},
                        child: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                              color: AppStyle.white.withOpacity(0.8),
                              shape: BoxShape.circle),
                          child: const Icon(
                            Remix.play_fill,
                            color: AppStyle.black,
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              )
            : fileImage != null
                ? Image.file(
                    fileImage!,
                    height: height,
                    width: width,
                    fit: fit,
                  )
                : AppHelpers.checkIsSvg(url)
                    ? SvgPicture.network(
                        '$url',
                        width: width?.r,
                        height: height?.r,
                        fit: BoxFit.cover,
                        placeholderBuilder: (_) => Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(radius.r),
                            color: AppStyle.white,
                          ),
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: '$url',
                        width: width?.r,
                        height: height?.r,
                        fit: fit ?? BoxFit.cover,
                        progressIndicatorBuilder: (_, __, ___) => Container(
                          height: height?.r,
                          width: width?.r,
                          decoration: BoxDecoration(
                            color: AppStyle.shimmerBase,
                          ),
                          child: (width ?? 0) > 58
                              ? Center(
                                  child: Text(
                                    AppHelpers.getTranslation(
                                        AppHelpers.getAppName() ?? ''),
                                    style: AppStyle.interNormal(
                                        color: AppStyle.textGrey, size: 12),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(errorRadius.r),
                            color: errorBackground ?? AppStyle.bgGrey,
                          ),
                          alignment: Alignment.center,
                          child: title?.isNotEmpty ?? false
                              ? Text(title!)
                              : Icon(
                                  Remix.image_line,
                                  color: AppStyle.black.withOpacity(0.5),
                                  size: 20.r,
                                ),
                        ),
                      ));
  }
}
