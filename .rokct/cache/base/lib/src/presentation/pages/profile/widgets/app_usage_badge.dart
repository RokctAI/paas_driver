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

// lib/src/presentation/pages/profile/widgets/app_usage_badge.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/utils/app_usage_service.dart';

/// Pill badge showing how often the signed-in user opened the app —
/// this ISO week and this calendar year, e.g.
/// `3 days in app this week · 45 days in app this year`.
///
/// Promoted from marketplace_sdk's profile footer (it always read only
/// base_sdk symbols) so every SDK's profile footer can reuse it. The
/// year figure comes from the backend `app-usage/stats` endpoint via
/// [AppUsageService]; the week figure prefers a backend-served
/// `days_in_app_this_week` and falls back to the service's local
/// once-per-day counter. Both segments render by default; pass
/// [showThisWeek] / [showThisYear] to trim the badge to one figure.
class AppUsageBadge extends StatefulWidget {
  /// Whether the current ISO week's figure is shown. Defaults to true
  /// per the product ask ("can be used for this week too, not just
  /// year"); pass false to restore the pre-1.26 year-only badge.
  final bool showThisWeek;

  /// Whether the calendar-year figure is shown. Defaults to true.
  final bool showThisYear;

  const AppUsageBadge({
    super.key,
    this.showThisWeek = true,
    this.showThisYear = true,
  });

  @override
  State<AppUsageBadge> createState() => _AppUsageBadgeState();
}

class _AppUsageBadgeState extends State<AppUsageBadge> {
  int daysInAppThisYear = 0;
  int daysInAppThisWeek = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppUsage();
  }

  Future<void> _loadAppUsage() async {
    // Only get stats, don't record usage here
    final stats = await AppUsageService.getAppUsageStats();

    if (mounted) {
      setState(() {
        daysInAppThisYear = stats['days_in_app_this_year'] ?? 0;
        daysInAppThisWeek = stats[AppUsageService.weekStatKey] ?? 0;
        isLoading = false;
      });
    }
  }

  String get _label {
    final segments = <String>[
      if (widget.showThisWeek)
        '$daysInAppThisWeek ${AppHelpers.getTranslation(TrKeys.daysInAppThisWeek)}',
      if (widget.showThisYear)
        '$daysInAppThisYear ${AppHelpers.getTranslation(TrKeys.daysInAppThisYear)}',
    ];
    return segments.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: AppStyle.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: isLoading
          ? SizedBox(
              width: 16.r,
              height: 16.r,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppStyle.primary),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Remix.calendar_2_line,
                  color: AppStyle.primary,
                  size: 16.r,
                ),
                SizedBox(width: 4.w),
                Text(
                  _label,
                  style: AppStyle.interNormal(
                    size: 12.sp,
                    color: AppStyle.primary,
                  ),
                ),
              ],
            ),
    );
  }
}
