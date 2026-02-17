import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:driver/presentation/styles/style.dart';
import 'buttons_bouncing_effect.dart';

class SocialButton extends StatelessWidget {
  final IconData iconData;
  final Function() onPressed;
  final String title;
  final bool isLoading;

  const SocialButton({
    super.key,
    required this.iconData,
    required this.onPressed,
    required this.title,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ButtonsBouncingEffect(
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          constraints: BoxConstraints(minWidth: 96.r, minHeight: 36.r),
          decoration: BoxDecoration(
            color: Style.white,
            borderRadius: BorderRadius.circular(10.r),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(iconData, color: Style.textColor, size: 16.r),
              8.horizontalSpace,
              isLoading
                  ? SizedBox(
                      height: 12.r,
                      width: 12.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.r,
                        color: Style.black,
                      ),
                    )
                  : Text(
                      title,
                      style: Style.interNormal(
                        size: 12,
                        color: Style.textColor,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
