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
