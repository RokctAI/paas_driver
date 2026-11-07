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

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/presentation/components/blur_wrap.dart';

class ModalWrap extends StatelessWidget {
  final Widget body;

  /// When true, the frosted fill follows the app theme
  /// ([AppStyle.surfaceFor] for the current brightness) instead of white.
  /// Default false keeps the light fill for every existing caller; a caller
  /// opts in only after its body text and icons are theme-aware.
  final bool themed;

  const ModalWrap({super.key, required this.body, this.themed = false});

  @override
  Widget build(BuildContext context) {
    final Color fill = themed
        ? AppStyle.surfaceFor(Theme.of(context).brightness).withOpacity(0.9)
        : AppStyle.white.withOpacity(0.9);
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
          color: fill,
          boxShadow: [
            BoxShadow(
              color: AppStyle.blackColor.withOpacity(0.25),
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
