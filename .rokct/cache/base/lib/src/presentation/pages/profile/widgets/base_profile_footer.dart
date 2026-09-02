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

import 'package:base_sdk/src/presentation/pages/profile/widgets/app_usage_badge.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

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

  @override
  Widget build(BuildContext context) {
    // Wrap, not Row: on narrow screens (or a caller overriding the badge
    // back to both figures) the line can exceed the width; extra items
    // flow to a second centred line instead of overflowing.
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 4,
      children: [
        Text(
          AppHelpers.getAppName() ?? "",
          style: AppStyle.interBold(color: AppStyle.primary),
        ),
        const SizedBox(width: 4),
        Icon(
          Remix.checkbox_blank_circle_fill,
          size: 8,
          // Mode-resolving ink so the separator follows the theme.
          color: AppStyle.textPrimary,
        ),
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
                style: AppStyle.interNormal(color: AppStyle.textPrimary),
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
        // Online/Offline dot backed by a real backend probe (guest
        // api_status).
        FutureBuilder<bool>(
          future: AppConnectivity.backendAvailability(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }
            final isOnline = snapshot.data!;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 8),
                Icon(
                  Remix.checkbox_blank_circle_fill,
                  size: 20,
                  color: isOnline ? AppStyle.green : AppStyle.red,
                ),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: isOnline ? AppStyle.green : AppStyle.red,
                  ),
                ),
              ],
            );
          },
        ),
        SizedBox(width: 16.w),
        const AppUsageBadge(),
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
