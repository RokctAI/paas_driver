// Copyright (c) 2026 RokctAI
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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

import 'package:weather_sdk/src/common/application/warnings/weather_warnings_state.dart';
import 'package:weather_sdk/src/common/infrastructure/services/weather_notice_ack_service.dart';
import 'package:weather_sdk/src/common/infrastructure/services/weather_warnings_service.dart';

/// Slim severe-weather heads-up card. Hosts drop it anywhere in body flow
/// (or embed it via the manifest's zero-arg `weatherWarningsBanner` seam);
/// it sizes itself and NEVER shows anything unless there is at least one
/// active warning to show.
///
/// Behavior contract (severe-weather integration design, section 4.1):
/// - No active warnings, cmd failure, empty response, or a backend that
///   does not have the warnings endpoint yet all render
///   [SizedBox.shrink] - no banner, no error text, no retry chip, zero
///   layout shift. Failures are an admin concern, never an end-user one.
/// - Collapsed, it shows only the single most urgent warning: headline +
///   friendly message (all copy is authored server-side; this widget adds
///   no wording of its own). Tapping expands the remaining warnings.
/// - Dismissible per day: the close control hides the banner until
///   tomorrow, but a CHANGED warning set (new/updated warnings) reappears
///   immediately.
/// - Styling stays calm: the suite's standard card surface with one muted,
///   severity-independent accent. Severity is expressed ONLY through the
///   server-authored wording, never through color-coded levels, labels,
///   badges or red-alert/flashing treatment - in South Africa only the
///   national weather service may issue official severe-weather warnings,
///   so this surface must read as a friendly heads-up, not an official
///   warning system.
/// - Advisory-only state (every active notice is the soft "advisory" tier -
///   a neighbor-propagation notice that conditions nearby may reach this
///   area) renders the same card in its most muted form: slightly smaller,
///   quieter type and tighter padding than the heads-up presentation. Copy
///   is still the server's calm wording verbatim, and the attribution line
///   still renders. With mixed severities the most urgent notice wins the
///   collapsed line (as always), at the default presentation.
/// - The attribution line "Weather data by Open-Meteo.com" is always
///   rendered with the warnings (CC-BY-4.0 requirement).
class SevereWeatherBanner extends ConsumerStatefulWidget {
  const SevereWeatherBanner({super.key});

  @override
  ConsumerState<SevereWeatherBanner> createState() =>
      _SevereWeatherBannerState();
}

class _SevereWeatherBannerState extends ConsumerState<SevereWeatherBanner> {
  static const String _dismissPrefKey = 'severe_weather_banner_dismissed';

  bool _expanded = false;

  /// Null while the stored dismissal is still loading - the banner stays
  /// hidden until we know it was NOT dismissed, so it can never flash in
  /// and disappear.
  String? _dismissedRecord;
  bool _dismissLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadDismissal();
  }

  Future<void> _loadDismissal() async {
    String? record;
    try {
      final prefs = await SharedPreferences.getInstance();
      record = prefs.getString(_dismissPrefKey);
    } catch (_) {
      record = null; // Unreadable prefs = not dismissed.
    }
    if (!mounted) return;
    setState(() {
      _dismissedRecord = record;
      _dismissLoaded = true;
    });
  }

  String _todayStamp() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  String _dismissRecordFor(WeatherWarningsState state) =>
      '${_todayStamp()}|${state.contentKey}';

  bool _isDismissed(WeatherWarningsState state) =>
      _dismissedRecord == _dismissRecordFor(state);

  /// "seen" delivery receipts for every notice the banner is rendering.
  /// Fire-and-forget telemetry: the service de-dupes per warning per app
  /// session and swallows every failure, so calling this from build is
  /// safe, idempotent, and can never block or slow a frame (see
  /// WeatherNoticeAckService).
  void _ackSeen(WeatherWarningsState state) {
    final ack = ref.read(weatherNoticeAckServiceProvider);
    for (final warning in state.warnings) {
      ack.ackSeen(warning);
    }
  }

  /// "opened" receipts when the user taps to expand the notices. Same
  /// fire-and-forget contract as [_ackSeen].
  void _ackOpened(WeatherWarningsState state) {
    final ack = ref.read(weatherNoticeAckServiceProvider);
    for (final warning in state.warnings) {
      ack.ackOpened(warning);
    }
  }

  /// Subtle freshness marker for cache-served notices, e.g. "As of 14:30"
  /// - the label routes through base_sdk's translation layer (tr_key
  /// `as.of`, declared in this SDK's manifest; AppHelpers falls back to the
  /// humanized key until a translation store value exists).
  String _freshnessLabel(DateTime cachedAt) {
    final label = AppHelpers.getTranslation('as.of');
    final time = DateFormat.Hm().format(cachedAt.toLocal());
    return '$label $time';
  }

  Future<void> _dismissForToday(WeatherWarningsState state) async {
    final record = _dismissRecordFor(state);
    setState(() => _dismissedRecord = record);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dismissPrefKey, record);
    } catch (_) {
      // Persisting is best-effort; the in-memory dismissal already applied.
    }
  }

  /// [muted] is the advisory-only presentation: same layout and colors
  /// (severity is never color-coded), just smaller, quieter type.
  Widget _buildWarningText(
    SevereWeatherWarning warning, {
    bool muted = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          warning.headline,
          style: GoogleFonts.inter(
            fontSize: muted ? 13.sp : 14.sp,
            fontWeight: muted ? FontWeight.w500 : FontWeight.w600,
            color: AppStyle.textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          warning.message,
          style: GoogleFonts.inter(
            fontSize: muted ? 12.sp : 13.sp,
            height: 1.35,
            color: AppStyle.textDarkSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildExtraWarning(
    SevereWeatherWarning warning, {
    bool muted = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6.h, right: 8.w),
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(
              color: AppStyle.textDarkSecondary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(child: _buildWarningText(warning, muted: muted)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(weatherWarningsProvider);
    final lead = state.mostSevere;

    // Nothing to show, or dismissal still unknown/applied: render nothing.
    if (lead == null || !_dismissLoaded || _isDismissed(state)) {
      return const SizedBox.shrink();
    }

    // The banner is definitely rendering with data past this point: report
    // delivery ("seen") for each visible notice. De-duped per app session
    // inside the service, so rebuilds cost one Set lookup and no I/O.
    _ackSeen(state);

    final extras = state.warnings.skip(1).toList();

    // Warnings arrive most-urgent-first, so an advisory lead means EVERY
    // active notice is the soft advisory tier - the whole card takes the
    // muted presentation. Any heads_up or warning present outranks the
    // advisories, leads the collapsed line, and keeps the default look.
    final muted = lead.isAdvisory;

    return Container(
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppStyle.strokeDarkSubtle),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.r),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // One muted accent for every notice: severity must never be
              // color-coded (no yellow/orange/red levels) - urgency lives
              // in the server-authored wording alone.
              Container(width: 4.w, color: AppStyle.textDarkSecondary),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: extras.isEmpty
                      ? null
                      : () {
                          final expanding = !_expanded;
                          setState(() => _expanded = expanding);
                          // Report engagement ("opened") when the user
                          // expands the notices - never on collapse.
                          if (expanding) _ackOpened(state);
                        },
                  child: Padding(
                    padding: EdgeInsets.all(muted ? 10.sp : 12.sp),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildWarningText(lead, muted: muted),
                            ),
                            SizedBox(width: 8.w),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _dismissForToday(state),
                              child: Padding(
                                padding: EdgeInsets.all(2.sp),
                                child: Icon(
                                  Remix.close_line,
                                  size: 16.sp,
                                  color: AppStyle.textDarkSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_expanded)
                          ...extras.map(
                            (w) => _buildExtraWarning(w, muted: muted),
                          ),
                        if (!_expanded && extras.isNotEmpty) ...[
                          SizedBox(height: 6.h),
                          Text(
                            extras.length == 1
                                ? '1 more notice - tap to view'
                                : '${extras.length} more notices - tap to view',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: AppStyle.textDarkSecondary,
                            ),
                          ),
                        ],
                        if (state.fromCache && state.cachedAt != null) ...[
                          SizedBox(height: 6.h),
                          // Cache-served notices carry a subtle freshness
                          // marker ("As of 14:30") so nobody mistakes an
                          // offline copy for a live update. Same muted
                          // style as the attribution - calm, never an
                          // error or staleness alarm.
                          Text(
                            _freshnessLabel(state.cachedAt!),
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              color: AppStyle.textDarkSecondary,
                            ),
                          ),
                        ],
                        SizedBox(height: 8.h),
                        // CC-BY-4.0 credit: always visible with warning data.
                        Text(
                          state.attribution,
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            color: AppStyle.textDarkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
