import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import '../styles/style.dart';

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
    this.bgColor = Style.blackColorOpacity,
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
                        baseColor: Style.shimmerBase,
                        highlightColor: Style.shimmerHighlight,
                        child: Container(
                          height: size.r,
                          decoration: BoxDecoration(
                            color: Style.white,
                            borderRadius: BorderRadius.circular(size.r / 2),
                          ),
                        ),
                      );
                    },
                    errorWidget: (context, url, error) {
                      return Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Style.greyColor,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          FlutterRemix.image_line,
                          color: Style.black,
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
