import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

// Legacy manager toggle palette — not part of base AppStyle's tokens.
const Color _toggleColor = Color(0xFFE7E7E7);
const Color _toggleShadowColor = Color(0xFF6B6B6B);

/// The manager-flavored on/off switch, promoted verbatim from paas_manager's
/// retired host `lib/presentation/component/custom_toggle.dart` (manager
/// migration M5) so the commerce manager templates (products' create/edit
/// food + addon forms, merchants' working-time modal and open/closed logout
/// row) can import it from base_sdk instead of the host tree.
///
/// Third same-named sibling by design: `custom_toggle.dart` (titled row
/// card) and `custom_toggle2.dart` (light/dark pill) already coexist this
/// way, and the call sites were written against THIS constructor signature —
/// an optional external [controller], an [onChange] callback, and [isText]
/// to render translated open/close labels inside the track.
class CustomToggle extends StatefulWidget {
  final ValueNotifier<bool>? controller;
  final bool isText;
  final Function(bool?)? onChange;

  const CustomToggle(
      {super.key, this.controller, this.onChange, this.isText = false});

  @override
  State<CustomToggle> createState() => _CustomToggleState();
}

class _CustomToggleState extends State<CustomToggle> {
  // No listener wiring in initState and no controller dispose here: the
  // controller is owned by the parent, and onChange is forwarded from
  // AdvancedSwitch's own callback below.
  @override
  Widget build(BuildContext context) {
    return AdvancedSwitch(
      controller: widget.controller,
      initialValue: widget.controller?.value ?? false,
      onChanged: (value) {
        widget.controller?.value = value;
        widget.onChange?.call(value);
      },
      activeColor: AppStyle.primary,
      inactiveColor: _toggleColor,
      borderRadius: BorderRadius.circular(10.r),
      width: 70.w,
      height: 30.h,
      enabled: true,
      disabledOpacity: 0.5,
      activeChild: widget.isText
          ? Padding(
              padding: REdgeInsets.only(left: 4.r),
              child: Text(
                AppHelpers.getTranslation(TrKeys.open),
                style: AppStyle.interNormal(size: 12.sp),
              ),
            )
          : const SizedBox.shrink(),
      inactiveChild: widget.isText
          ? Padding(
              padding: REdgeInsets.only(right: 4.r),
              child: Text(
                AppHelpers.getTranslation(TrKeys.close),
                style: AppStyle.interNormal(size: 12.sp),
              ),
            )
          : const SizedBox.shrink(),
      thumb: Container(
        margin: REdgeInsets.all(3),
        padding: REdgeInsets.symmetric(vertical: 7, horizontal: 9),
        decoration: BoxDecoration(
          color: AppStyle.white,
          borderRadius: BorderRadius.circular(6.r),
          boxShadow: [
            BoxShadow(
              color: _toggleShadowColor.withOpacity(0.4),
              spreadRadius: 0,
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          decoration: const BoxDecoration(color: _toggleColor),
        ),
      ),
    );
  }
}
