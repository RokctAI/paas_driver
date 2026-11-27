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

// lib/src/presentation/pages/profile/widgets/base_profile_footer.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/pages/profile/profile_host_scope.dart';
import 'package:base_sdk/src/presentation/pages/profile/widgets/app_usage_badge.dart';
import 'package:base_sdk/src/presentation/pages/profile/widgets/data_usage_badge.dart';
import 'package:base_sdk/src/presentation/components/app_rating_sheet.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/demo_session.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

/// The shared profile-footer meta row: app name, app version (with build
/// number in debug), the backend-probe Online/Offline dot and the
/// [AppUsageBadge]. Promoted from marketplace_sdk's profile footer — every
/// piece of it already read only base_sdk symbols.
///
/// Exported on its own (not just inside [BaseProfileFooter]) so an SDK
/// that overrides the `base.footer` section can still embed the standard
/// meta row inside its own composition — marketplace_sdk does exactly
/// that to keep its member-only links above the row.
class ProfileMetaRow extends StatelessWidget {
  const ProfileMetaRow({super.key});

  /// The answer the Online/Offline dot draws.
  ///
  /// The guided-tour build (`--dart-define=TOUR_MODE=true`) has no backend
  /// by design, so the api_status probe behind
  /// [AppConnectivity.backendAvailability] can only ever fail there, and
  /// the dot drew a red Offline on every tour still - a connection-failure
  /// state on a build that has no connection to fail, captured verbatim by
  /// the guided tour. Anything [DemoSession.demoActive] covers - the tour
  /// build, or a demo session served from the same fixtures - reads as
  /// connected without probing; a real session still asks the backend. The
  /// probe itself stays honest: the splash boot and `ConnectivityService`
  /// read it to gate the outbox drain and the translation fetch, and must
  /// keep seeing the backend as it is. Same gate the other SDKs put in
  /// front of their network paths.
  static Future<bool> _online() => DemoSession.demoActive
      ? Future<bool>.value(true)
      : AppConnectivity.backendAvailability();

  @override
  Widget build(BuildContext context) {
    // A BuildContext lookup for the mode, not the app-wide AppStyle.isDark
    // static (Ray, 2026-09-19: "glance doesnt change test immediately
    // untill you come back if you switched theme mode" — the same defect,
    // found here by the fleet audit that followed).
    //
    // This row resolved nothing from the context: its ink came from
    // AppStyle's statics, which are not an inherited widget, so a
    // theme-mode change scheduled no rebuild of it. And it is mounted
    // `const` by BaseProfileFooter below, so the flip provably cannot
    // reach it through a parent rebuild either — the same const-child
    // boundary the glance card sat behind. The version line goes further
    // still, being built inside a FutureBuilder. Reading the inherited
    // theme here makes this element a dependent, so the mode change itself
    // restyles the row while the profile is on screen, which is exactly
    // where the theme toggle lives.
    final Color ink = AppStyle.inkFor(Theme.of(context).brightness);

    // Wrap, not Row: on narrow screens (or a caller overriding the badge
    // back to both figures) the line can exceed the width; extra items
    // flow to a second centred line instead of overflowing.
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 4,
      children: [
        // App name in a primary-colour block, with the online status as a
        // small dot on its corner (Ray, 2026-11-27: "appname give it a
        // rectangle in primary color ... at the corner ... behave like the
        // sticks floating nav's online dot"). Replaces the separate
        // Online/Offline dot and text. The name's ink is picked from the
        // primary colour's own brightness, so it stays readable in both
        // theme modes and on any app's brand colour.
        const _AppNamePill(),
        const SizedBox(width: 8),
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, packageSnapshot) {
            if (packageSnapshot.hasData) {
              // Just a lowercase "v" prefix — the spelled-out "App
              // Version" label was too long for the row (product ask
              // 2026-08-28). No translation key ever backed this label
              // (the old words were hardcoded English), and "v" is a
              // locale-neutral version marker, so none is added.
              String versionDisplay;
              if (kDebugMode) {
                versionDisplay =
                    " v${packageSnapshot.data!.version}+${packageSnapshot.data!.buildNumber}";
              } else {
                versionDisplay = " v${packageSnapshot.data!.version}";
              }

              return Text(
                versionDisplay,
                style: AppStyle.interNormal(color: ink),
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
        // The usage badge counts a signed-in user's app opens; in the host's
        // anonymous mode there is no such user, so it is left out.
        if (ProfileHostScope.of(context).hasAccount) ...[
          SizedBox(width: 16.w),
          const AppUsageBadge(),
        ],
        // Data used, counted on this device (DataUsageMeter), so it shows
        // signed in or not. Ray, 2026-11-06: time in the app was here,
        // data used was not.
        SizedBox(width: 8.w),
        const DataUsageBadge(),
        // The app's own rating screen (see AppRating): a 4 or 5 goes on to the
        // store's review sheet in a listed app, anything else stays private.
        SizedBox(width: 8.w),
        InkWell(
          key: const ValueKey('profile_rate_app'),
          onTap: () => AppRatingSheet.show(context),
          child: Text(
            AppHelpers.getTranslation(TrKeys.rateThisApp),
            style: AppStyle.interBold(color: AppStyle.primary),
          ),
        ),
        // Licence notices for the open-source packages the app ships
        // (Ray, 2026-11-27): Flutter's own licence page, which lists every
        // package that registers a LICENSE file. A dot separates it from
        // "Rate this app" (Ray, 2026-11-27), the same dot as after the name.
        SizedBox(width: 6.w),
        Icon(
          Remix.checkbox_blank_circle_fill,
          size: 8,
          color: ink,
        ),
        SizedBox(width: 6.w),
        InkWell(
          key: const ValueKey('profile_licences'),
          onTap: () => showLicensePage(
            context: context,
            applicationName: AppHelpers.getAppName(),
          ),
          child: Text(
            AppHelpers.getTranslation(TrKeys.licences),
            style: AppStyle.interBold(color: AppStyle.primary),
          ),
        ),
      ],
    );
  }
}

/// base_sdk's default `base.footer` profile section: the [ProfileMetaRow]
/// alone, lightly padded. Registered by the generic profile host via
/// `ProfileSectionRegistry.I.ensureDefaultSections()` only when no SDK
/// claimed the [sectionId] slot first.
///
/// Overriding: register your own [ProfileSection] with id [sectionId]
/// from a `di_hooks` entry — bootstrap registration always precedes the
/// host page's mount, and duplicate ids are first-wins, so the SDK's
/// section replaces this default. Hiding: register a [sectionId] section
/// whose `visible` gate resolves false.
class BaseProfileFooter extends StatelessWidget {
  /// Section id of the default footer slot.
  static const String sectionId = 'base.footer';

  /// Section order of the default footer — far above any conventional
  /// SDK section order so the footer lands last.
  static const int sectionOrder = 1000;

  const BaseProfileFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.r),
      child: const ProfileMetaRow(),
    );
  }
}

/// The app name in a primary-colour block with the backend-probe dot on its
/// top-right corner: green online, red offline, nothing until the probe
/// answers. The dot carries a ring in the page colour so it reads as sitting
/// on the corner. The probe is the same one the old Online/Offline row used
/// (see [ProfileMetaRow._online]), re-asked when a demo session starts or
/// ends.
class _AppNamePill extends StatefulWidget {
  const _AppNamePill();

  @override
  State<_AppNamePill> createState() => _AppNamePillState();
}

/// Offline, the dot blinks the way Sticks' floating-nav connection dot does
/// (Ray, 2026-11-27: "copy the behavior of floating nav"): opacity 1 to 0.25
/// and back every 900 ms. Online, or with animations turned off on the
/// phone, it stays still.
class _AppNamePillState extends State<_AppNamePill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    value: 1,
  );

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  void _follow(bool online, bool still) {
    if (online || still) {
      if (_blink.isAnimating) _blink.stop();
      _blink.value = 1;
    } else if (!_blink.isAnimating) {
      _blink.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color fill = AppStyle.primary;
    final Color label =
        ThemeData.estimateBrightnessForColor(fill) == Brightness.dark
        ? Colors.white
        : Colors.black;
    final Color ring = Theme.of(context).scaffoldBackgroundColor;
    final bool still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return ListenableBuilder(
      listenable: DemoSession.instance,
      builder: (context, _) => FutureBuilder<bool>(
        key: ValueKey<bool>(DemoSession.demoActive),
        future: ProfileMetaRow._online(),
        builder: (context, snapshot) {
          final bool? isOnline = snapshot.data;
          // Started or stopped after the frame, not while building it.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _follow(isOnline ?? true, still);
          });
          return Semantics(
            label: isOnline == null
                ? null
                : AppHelpers.getTranslation(
                    isOnline ? TrKeys.online : TrKeys.offline,
                  ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  key: const ValueKey('profile_app_name_pill'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    AppHelpers.getAppName() ?? "",
                    style: AppStyle.interBold(color: label),
                  ),
                ),
                if (isOnline != null)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: FadeTransition(
                      opacity: Tween<double>(begin: .25, end: 1).animate(_blink),
                      child: Container(
                        key: const ValueKey('profile_online_dot'),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOnline ? AppStyle.green : AppStyle.red,
                          border: Border.all(color: ring, width: 2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
