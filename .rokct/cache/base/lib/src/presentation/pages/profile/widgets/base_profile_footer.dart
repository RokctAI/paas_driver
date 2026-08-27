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
    // Wrap, not Row: with both week and year usage figures the line can
    // exceed narrow screens; extra items flow to a second centred line
    // instead of overflowing.
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
              String versionDisplay;
              if (kDebugMode) {
                versionDisplay =
                    " App Version ${packageSnapshot.data!.version}+${packageSnapshot.data!.buildNumber}";
              } else {
                versionDisplay =
                    " App Version ${packageSnapshot.data!.version}";
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
