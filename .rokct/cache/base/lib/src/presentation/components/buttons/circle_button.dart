import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/presentation/components/buttons/animation_button_effect2.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

class CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color backgroundColor;
  final double size;
  final double iconSize;

  const CircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.backgroundColor = AppStyle.textGrey,
    this.size = 36,
    this.iconSize = 21,
  });

  @override
  Widget build(BuildContext context) {
    return ButtonEffectAnimation(
      onTap: onTap,
      child: Container(
        height: size.r,
        width: size.r,
        padding: REdgeInsets.all(4),
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(icon, color: AppStyle.buttonFont, size: iconSize.r),
        ),
      ),
    );
  }
}


