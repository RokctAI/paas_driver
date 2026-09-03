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


import 'package:cached_network_image/cached_network_image.dart';
import 'dart:typed_data';

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
    // Inline ("data:") images carry their own pixels: the demo seed data
    // uses them so a demo build - which talks to no backend, and on the CI
    // tour emulator has no dependable route to an image host either - shows
    // real artwork instead of this widget's broken-image error state. Checked
    // before checkIsSvg(), whose filename-extension test cannot see an SVG
    // inside a data URI.
    if (AppHelpers.isInlineImage(url)) {
      return _buildInlineImage();
    }
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

  /// Renders an inline `data:` image: SVG markup through [SvgPicture.string],
  /// anything else (png/jpeg/webp payloads) through [Image.memory]. Falls
  /// back to a plain tinted box when the payload cannot be decoded, so a
  /// malformed URI degrades the same way an unreachable URL does.
  Widget _buildInlineImage() {
    if (AppHelpers.isInlineSvg(url)) {
      final String svg = AppHelpers.inlineImagePayload(url);
      if (svg.isEmpty) return _inlineFallback();
      return SvgPicture.string(
        svg,
        width: width,
        height: height,
        fit: fit,
      );
    }
    final Uint8List? bytes = AppHelpers.inlineImageBytes(url);
    if (bytes == null || bytes.isEmpty) return _inlineFallback();
    return Image.memory(
      bytes,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _inlineFallback(),
    );
  }

  Widget _inlineFallback() => Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: bgColor,
        ),
      );
}
