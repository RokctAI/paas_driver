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

/// The one time period the profile footer's [AppUsageBadge] renders,
/// e.g. `3 days in app this week` OR `45 days in app this year` — never
/// both (the pre-1.31 badge carried both figures; per the product ask
/// "the bottom seem to be carrying year and week — let home SDKs
/// choose", it now shows exactly one).
enum AppUsagePeriod {
  /// The current ISO week's figure (`days_in_app_this_week`).
  week,

  /// The calendar year's figure (`days_in_app_this_year`).
  year,
}

/// Pill badge showing how often the signed-in user opened the app in
/// ONE period — this ISO week or this calendar year — e.g.
/// `45 days in app this year`.
///
/// Promoted from marketplace_sdk's profile footer (it always read only
/// base_sdk symbols) so every SDK's profile footer can reuse it. The
/// year figure comes from the backend `app-usage/stats` endpoint via
/// [AppUsageService]; the week figure prefers a backend-served
/// `days_in_app_this_week` and falls back to the service's local
/// once-per-day counter.
///
/// Which period renders is the app's HOME SDK's choice via the [period]
/// seam; the default is [AppUsagePeriod.year], so apps whose home SDK
/// sets nothing keep the historical year figure. Per-instance
/// [showThisWeek] / [showThisYear] overrides still exist for a caller
/// that must pin a specific composition regardless of the seam.
///
/// SMALL COUNTS render adaptively (per the product ask to show a finer
/// unit "if hours are small before we move to days"): the telemetry lane
/// records at most one `app_open` event per day and no session durations,
/// so true hour figures cannot be derived — the honest sub-day rendering
/// is copy, not arithmetic. `0` reads "Less than a day in app this year"
/// (the user is in the app right now, so a literal "0 days" was always
/// false-feeling) and `1` reads the singular "1 day in app this year";
/// from 2 the plural day figure takes over unchanged.
class AppUsageBadge extends StatefulWidget {
  /// App-wide period seam — the home SDK's to set, exactly like the
  /// brand palette through `AppStyle.injectBrandColors`: assign once at
  /// the home SDK's bootstrap/registration point, before the badge first
  /// builds. LAST-WINS by design (plain assignment, mirroring
  /// injectBrandColors — an idempotent re-registration simply re-asserts
  /// the same value); only a home SDK should write it. Defaults to
  /// [AppUsagePeriod.year] so every app whose home SDK does not choose —
  /// marketplace included — keeps the year figure.
  static AppUsagePeriod period = AppUsagePeriod.year;

  /// Per-instance override: forces the ISO-week figure on (true) or off
  /// (false) regardless of [period]. Null (the default) defers to
  /// [period].
  final bool? showThisWeek;

  /// Per-instance override for the calendar-year figure; null (the
  /// default) defers to [period].
  final bool? showThisYear;

  const AppUsageBadge({
    super.key,
    this.showThisWeek,
    this.showThisYear,
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

  // Effective visibility: an explicit per-instance override wins;
  // otherwise the home-SDK-chosen [AppUsageBadge.period] picks the one
  // figure to show.
  bool get _showWeek =>
      widget.showThisWeek ?? AppUsageBadge.period == AppUsagePeriod.week;

  bool get _showYear =>
      widget.showThisYear ?? AppUsageBadge.period == AppUsagePeriod.year;

  // Lower-cases a sentence-cased translation fragment for use after a
  // leading count ("3 days in app...", not "3 Days in app..."). Guarded to
  // an uppercase-then-lowercase Latin start so acronyms and non-Latin
  // scripts pass through untouched.
  static String _midSentence(String fragment) {
    if (!RegExp('^[A-Z][a-z]').hasMatch(fragment)) return fragment;
    return fragment[0].toLowerCase() + fragment.substring(1);
  }

  // One period's segment: sub-day copy at 0, the singular row at 1, the
  // counted plural from 2 (see the class doc's SMALL COUNTS note).
  static String _segment(
    int count, {
    required String zeroKey,
    required String oneKey,
    required String manyKey,
  }) {
    if (count == 0) return AppHelpers.getTranslation(zeroKey);
    final key = count == 1 ? oneKey : manyKey;
    return '$count ${_midSentence(AppHelpers.getTranslation(key))}';
  }

  String get _label {
    final segments = <String>[
      if (_showWeek)
        _segment(
          daysInAppThisWeek,
          zeroKey: TrKeys.lessThanADayInAppThisWeek,
          oneKey: TrKeys.dayInAppThisWeek,
          manyKey: TrKeys.daysInAppThisWeek,
        ),
      if (_showYear)
        _segment(
          daysInAppThisYear,
          zeroKey: TrKeys.lessThanADayInAppThisYear,
          oneKey: TrKeys.dayInAppThisYear,
          manyKey: TrKeys.daysInAppThisYear,
        ),
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
                // Flexible + ellipsis: in a narrow surface (a plane-spread
                // profile column) the long usage label truncates instead
                // of overflowing; where it fits, min-sized as before.
                Flexible(
                  child: Text(
                    _label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyle.interNormal(
                      size: 12.sp,
                      color: AppStyle.primary,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
