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

import 'package:base_sdk/src/models/data/profile_data.dart';
import 'package:base_sdk/src/presentation/components/user_avatar.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/remembered_account.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';

/// "Welcome back": the sign-in page shown when Log out kept this device's
/// account (base_sdk RememberedAccount, Ray 2026-11-27). Tapping the account
/// opens the usual login sheet with the email or phone filled in; the
/// password is still asked for. "Use another account" shows the app's own
/// login page; "Remove" forgets the account on this device.
class WelcomeBackEntry extends StatelessWidget {
  const WelcomeBackEntry({
    super.key,
    required this.account,
    required this.onContinue,
    required this.onAnotherAccount,
    required this.onRemove,
    required this.onSkip,
  });

  static const Key accountKey = ValueKey('auth.welcome_back.account');
  static const Key anotherKey = ValueKey('auth.welcome_back.another');
  static const Key removeKey = ValueKey('auth.welcome_back.remove');

  final RememberedAccount account;
  final VoidCallback onContinue;
  final VoidCallback onAnotherAccount;
  final VoidCallback onRemove;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final Color ink = AppStyle.inkFor(brightness);
    final Color muted = ink.withValues(alpha: 0.6);
    final Color tile = ink.withValues(alpha: 0.06);
    return ColoredBox(
      color: AppStyle.surfaceFor(brightness),
      child: SafeArea(
        child: Padding(
          padding: REdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Every login screen has a Skip (Ray, 2026-11-27).
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: TextButton(
                  onPressed: onSkip,
                  child: Text(
                    AppHelpers.getTranslation(TrKeys.skip),
                    style: AppStyle.interSemi(size: 14.sp, color: ink),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                AppHelpers.getTranslation(TrKeys.welcomeBack),
                style: AppStyle.interSemi(size: 28.sp, color: ink),
              ),
              24.verticalSpace,
              Material(
                color: tile,
                borderRadius: BorderRadius.circular(16.r),
                child: InkWell(
                  key: accountKey,
                  borderRadius: BorderRadius.circular(16.r),
                  onTap: onContinue,
                  child: Padding(
                    padding: REdgeInsets.all(14),
                    child: Row(
                      children: [
                        UserAvatar(
                          user: ProfileData(
                            firstname: account.name,
                            img: account.img,
                          ),
                          size: 48.r,
                        ),
                        14.horizontalSpace,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                account.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppStyle.interSemi(
                                  size: 16.sp,
                                  color: ink,
                                ),
                              ),
                              if (account.login != null &&
                                  account.login != account.name)
                                Text(
                                  account.login!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppStyle.interNormal(
                                    size: 13.sp,
                                    color: muted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Icon(
                          Remix.arrow_right_s_line,
                          color: muted,
                          size: 22.r,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  key: removeKey,
                  onPressed: onRemove,
                  child: Text(
                    AppHelpers.getTranslation(TrKeys.removeFromThisDevice),
                    style: AppStyle.interNormal(size: 13.sp, color: muted),
                  ),
                ),
              ),
              const Spacer(),
              OutlinedButton(
                key: anotherKey,
                onPressed: onAnotherAccount,
                style: OutlinedButton.styleFrom(
                  minimumSize: Size.fromHeight(52.r),
                  shape: const StadiumBorder(),
                  side: BorderSide(color: ink.withValues(alpha: 0.3)),
                ),
                child: Text(
                  AppHelpers.getTranslation(TrKeys.useAnotherAccount),
                  style: AppStyle.interSemi(size: 15.sp, color: ink),
                ),
              ),
              24.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }
}
