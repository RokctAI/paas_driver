// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
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


import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/presentation/components/custom_toggle3.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

/// Toggle row for profile sections: leading icon, title, optional subtitle,
/// trailing on/off switch.
class ProfileSwitchTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ProfileSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  State<ProfileSwitchTile> createState() => _ProfileSwitchTileState();
}

class _ProfileSwitchTileState extends State<ProfileSwitchTile> {
  late final ValueNotifier<bool> _controller = ValueNotifier(widget.value);

  @override
  void didUpdateWidget(ProfileSwitchTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.value) {
      _controller.value = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 12.r),
      child: Row(
        children: [
          Icon(widget.icon, size: 22.sp, color: AppStyle.textPrimary),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: AppStyle.interSemi(
                    size: 15.sp,
                    color: AppStyle.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                  2.verticalSpace,
                  Text(
                    widget.subtitle!,
                    style: AppStyle.interNormal(
                      size: 13.sp,
                      color: AppStyle.textDarkSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          8.horizontalSpace,
          CustomToggle(
            controller: _controller,
            onChange: (value) => widget.onChanged(value ?? false),
          ),
        ],
      ),
    );
  }
}
