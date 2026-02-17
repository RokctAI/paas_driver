import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:driver/presentation/styles/style.dart';
import 'blur_wrap.dart';

class ModalWrap extends StatelessWidget {
  final Widget body;

  const ModalWrap({super.key, required this.body});

  @override
  Widget build(BuildContext context) {
    return BlurWrap(
      radius: BorderRadius.only(
        topLeft: Radius.circular(16.r),
        topRight: Radius.circular(16.r),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
          ),
          color: Style.white.withValues(alpha: 0.9),
          boxShadow: [
            BoxShadow(
              color: Style.blackColor.withValues(alpha: 0.25),
              offset: const Offset(0, -2),
              blurRadius: 40,
              spreadRadius: 0,
            ),
          ],
        ),
        child: body,
      ),
    );
  }
}
