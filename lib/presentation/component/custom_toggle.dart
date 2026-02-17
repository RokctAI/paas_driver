import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../infrastructure/services/services.dart';
import '../styles/style.dart';

class CustomToggle extends StatefulWidget {
  final bool isOnline;
  final ValueChanged<bool> onChange;
  final bool isOrder;

  const CustomToggle({
    super.key,
    required this.isOnline,
    required this.onChange,
    this.isOrder = false,
  });

  @override
  State<CustomToggle> createState() => _CustomToggleState();
}

class _CustomToggleState extends State<CustomToggle> {
  var controller = ValueNotifier<bool>(false);

  @override
  void initState() {
    controller = ValueNotifier<bool>(widget.isOnline);
    controller.addListener(() {
      widget.onChange(controller.value);
    });
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdvancedSwitch(
      controller: controller,
      initialValue: controller.value,
      activeColor: Style.primary,
      inactiveColor: Style.toggleColor,
      borderRadius: BorderRadius.circular(10.r),
      width: widget.isOrder ? 70.w : 94.w,
      height: widget.isOrder ? 32.w : 40.h,
      enabled: true,
      disabledOpacity: 0.5,
      thumb: Container(
        margin: EdgeInsets.all(widget.isOrder ? 2.r : 4.r),
        padding: EdgeInsets.symmetric(vertical: 6.h),
        decoration: BoxDecoration(
          color: Style.white,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: Style.toggleShadowColor.withValues(alpha: 0.4),
              spreadRadius: 0,
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: double.infinity,
              width: 3.r,
              color: Style.toggleColor,
            ),
            2.horizontalSpace,
            Container(
              height: double.infinity,
              width: 3.r,
              color: Style.toggleColor,
            ),
          ],
        ),
      ),
      activeChild: Text(
        !widget.isOrder
            ? AppHelpers.getTranslation(TrKeys.online)
            : AppHelpers.getTranslation(TrKeys.active),
        style: Style.interNormal(
          size: widget.isOrder ? 10.sp : 12.sp,
          letterSpacing: -0.3,
          color: !widget.isOrder ? Style.buttonFontColor : Style.black,
        ),
      ),
      inactiveChild: Text(
        !widget.isOrder
            ? AppHelpers.getTranslation(TrKeys.offline)
            : AppHelpers.getTranslation(TrKeys.inActive),
        style: Style.interNormal(
          size: widget.isOrder ? 10.sp : 12.sp,
          letterSpacing: -0.3,
          color: Style.black,
        ),
      ),
    );
  }
}
