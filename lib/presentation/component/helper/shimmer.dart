import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:driver/presentation/styles/style.dart';

class ImageShimmer extends StatelessWidget {
  final double size;
  final bool isCircle;

  const ImageShimmer({super.key, required this.size, required this.isCircle});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Style.shimmerBase,
      highlightColor: Style.shimmerHighlight,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          color: Style.white,
        ),
      ),
    );
  }
}
