import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../infrastructure/services/local_storage.dart';
import '../styles/style.dart';

// ignore: must_be_immutable
class TitleAndIcon extends StatelessWidget {
  final String title;
  final double titleSize;
  final String? rightTitle;
  final bool isIcon;
  final Color rightTitleColor;
  VoidCallback? onRightTap;

  TitleAndIcon({
    super.key,
    this.isIcon = false,
    required this.title,
    this.rightTitle,
    this.rightTitleColor = Style.black,
    this.onRightTap,
    this.titleSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLtr = LocalStorage.getLangLtr();
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: Style.interSemi(size: 18.sp, color: Style.black),
            ),
          ),
          GestureDetector(
            onTap: onRightTap ?? () {},
            child: Row(
              children: [
                Text(
                  rightTitle ?? "",
                  style: Style.interRegular(
                    size: 14.sp,
                    color: rightTitleColor,
                  ),
                ),
                isIcon
                    ? Icon(
                        isLtr
                            ? Icons.keyboard_arrow_right
                            : Icons.keyboard_arrow_left,
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
