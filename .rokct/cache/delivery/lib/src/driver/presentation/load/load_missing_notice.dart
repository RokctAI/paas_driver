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
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

/// What `/load/sell` and `/load/return` show when the load they were asked
/// for is not in hand: a deep link into a load that has since closed, a
/// cold start straight onto the route, or several open loads and no id to
/// say which. One sentence and the way back — never a blank screen and
/// never a stepper over a load nobody can name.
class LoadMissingNotice extends StatelessWidget {
  const LoadMissingNotice({super.key, required this.titleKey});

  /// The screen the driver asked for, so the heading still tells him where
  /// he is.
  final String titleKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.surfaceFor(Theme.of(context).brightness),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 92.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppHelpers.getTranslation(titleKey),
                      style: AppStyle.interSemi(size: 21),
                    ),
                    20.verticalSpace,
                    Text(
                      AppHelpers.getTranslation('open_this_from_your_load'),
                      key: const Key('loadMissingNotice'),
                      style: AppStyle.interRegular(
                        size: 14,
                        color: AppStyle.secondaryInkFor(
                          Theme.of(context).brightness,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            PositionedDirectional(
              end: 16,
              bottom: 16,
              child: FloatingBackPill(
                back: FloatingNavBack(
                  icon: Remix.arrow_left_s_line,
                  label: AppHelpers.getTranslation(TrKeys.back),
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
