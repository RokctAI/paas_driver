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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/guide/guide_anchor.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

import 'package:auth_sdk/src/common/presentation/pages/auth/login/login_embedded_slots.dart';
import 'package:auth_sdk/src/common/services/auth_tr_keys.dart';
import 'package:auth_sdk/src/common/services/entry_config.dart';
import 'package:auth_sdk/src/common/services/platform_support.dart';

/// The login page's [AuthEntryLayout.card] welcome: a centred column on the
/// app's own surface (light or dark), the way a home SDK asks for it
/// through [AuthEntryConfig]. The Login and Register buttons open the same
/// sheets the photo layout opens, so sign-in itself is unchanged.
class LoginCardEntry extends StatelessWidget {
  const LoginCardEntry({
    super.key,
    required this.slots,
    required this.onLogin,
    required this.onRegister,
    required this.onSkip,
    this.onSocial,
  });

  final LoginEmbeddedSlots slots;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onSkip;

  /// Runs the chosen social sign-in (LoginPage wires it to the login
  /// notifier). Null hides the social buttons.
  final void Function(AuthSocialSignIn method)? onSocial;

  /// Translation key for the legal line's opening words.
  static const String termsLeadKey = AuthTrKeys.continueTermsLead;

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final Color ink = AppStyle.inkFor(brightness);
    final Color softInk = AppStyle.secondaryInkFor(brightness);
    final String? titleKey = AuthEntryConfig.titleTrKey;
    final String? subtitleKey = AuthEntryConfig.subtitleTrKey;
    final String? hero = AuthEntryConfig.heroAsset;
    final WidgetBuilder? heroBuilder = AuthEntryConfig.heroBuilder;
    final String appName = AppHelpers.getAppName() ?? '';
    final String? badgeKey = AuthEntryConfig.badgeTrKey;
    final String? signInLineKey = AuthEntryConfig.signInLineTrKey;
    final Color accent = AppStyle.primary;
    final List<AuthSocialSignIn> socials =
        onSocial == null || !supportsSocialSignIn
            ? const []
            : AuthEntryConfig.socialSignIns.where(socialSignInShown).toList();

    return ColoredBox(
      color: AppStyle.surfaceFor(brightness),
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: REdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (heroBuilder != null) ...[
                        heroBuilder(context),
                        24.verticalSpace,
                      ] else if (hero != null)
                        Image.asset(
                          hero,
                          width: 96.r,
                          height: 96.r,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      if (heroBuilder == null && hero != null)
                        24.verticalSpace,
                      if (badgeKey != null) ...[
                        Container(
                          padding: REdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            AppHelpers.getTranslation(badgeKey),
                            style: AppStyle.interNormal(size: 14, color: accent),
                          ),
                        ),
                        16.verticalSpace,
                      ],
                      Text(
                        titleKey != null
                            ? AppHelpers.getTranslation(titleKey)
                            : appName,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.sourceSerif4(
                          fontSize: 38.sp,
                          fontWeight: FontWeight.w600,
                          color: ink,
                          height: 1.12,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (subtitleKey != null) ...[
                        12.verticalSpace,
                        Text(
                          AppHelpers.getTranslation(subtitleKey),
                          textAlign: TextAlign.center,
                          style: AppStyle.interRegular(
                            size: 17,
                            color: softInk,
                          ).copyWith(height: 1.45),
                        ),
                      ],
                      40.verticalSpace,
                      if (signInLineKey != null) ...[
                        Text(
                          AppHelpers.getTranslation(signInLineKey),
                          textAlign: TextAlign.center,
                          style: AppStyle.interRegular(size: 14, color: softInk),
                        ),
                        14.verticalSpace,
                      ],
                      if (socials.isNotEmpty) ...[
                        for (final m in socials) ...[
                          _PillButton(
                            label: AppHelpers.getTranslation(_socialKey(m)),
                            icon: _socialIcon(m),
                            onTap: () => onSocial!(m),
                            filled: true,
                            brightness: brightness,
                          ),
                          10.verticalSpace,
                        ],
                        _OrDivider(color: softInk),
                        10.verticalSpace,
                      ],
                      GuideAnchor(
                        id: 'auth.login.button',
                        child: _PillButton(
                          label: AppHelpers.getTranslation(
                            AuthEntryConfig.loginLabelTrKey ??
                                (socials.isEmpty
                                    ? TrKeys.login
                                    : AuthTrKeys.continueWithEmail),
                          ),
                          icon: Remix.mail_line,
                          onTap: onLogin,
                          filled: socials.isEmpty,
                          brightness: brightness,
                        ),
                      ),
                      if (AuthEntryConfig.showsRegister) ...[
                        10.verticalSpace,
                        _PillButton(
                          label: AppHelpers.getTranslation(TrKeys.register),
                          onTap: onRegister,
                          filled: false,
                          brightness: brightness,
                        ),
                      ],
                      if (slots.hasLegalPages) ...[
                        20.verticalSpace,
                        _CardTermsLine(slots: slots, color: softInk),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (AuthEntryConfig.showsGuestSkip)
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: Padding(
                  padding: REdgeInsets.all(8),
                  child: TextButton(
                    onPressed: onSkip,
                    child: Text(
                      AppHelpers.getTranslation(TrKeys.skip),
                      style: AppStyle.interSemi(size: 14, color: ink),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Whether a declared social sign-in is offered here, behind the same gates
/// the login sheet uses (login_screen.dart): no social sign-in where
/// Firebase is unsupported (supportsSocialSignIn), Apple and Facebook only
/// once appleAndFacebookSignInVerified, Apple only on iOS and macOS, and
/// Google never there (Ray, 2026-11-27: "we dont show google in ios and we
/// dont show apple in android").
@visibleForTesting
bool socialSignInShown(AuthSocialSignIn m) => switch (m) {
      AuthSocialSignIn.google => kIsWeb ||
          (defaultTargetPlatform != TargetPlatform.iOS &&
              defaultTargetPlatform != TargetPlatform.macOS),
      AuthSocialSignIn.facebook => appleAndFacebookSignInVerified,
      AuthSocialSignIn.apple => appleAndFacebookSignInVerified &&
          !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS),
    };

String _socialKey(AuthSocialSignIn m) => switch (m) {
      AuthSocialSignIn.google => AuthTrKeys.continueWithGoogle,
      AuthSocialSignIn.facebook => AuthTrKeys.continueWithFacebook,
      AuthSocialSignIn.apple => AuthTrKeys.continueWithApple,
    };

IconData _socialIcon(AuthSocialSignIn m) => switch (m) {
      AuthSocialSignIn.google => Remix.google_fill,
      AuthSocialSignIn.facebook => Remix.facebook_circle_fill,
      AuthSocialSignIn.apple => Remix.apple_fill,
    };

/// "OR" between the social buttons and the email button.
class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Divider(color: color.withOpacity(0.4), thickness: 1),
    );
    return Padding(
      padding: REdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          line,
          Padding(
            padding: REdgeInsets.symmetric(horizontal: 14),
            child: Text(
              AppHelpers.getTranslation(AuthTrKeys.or),
              style: AppStyle.interNormal(size: 15, color: color),
            ),
          ),
          line,
        ],
      ),
    );
  }
}

/// A fully rounded button: filled = the main action (white on dark, ink on
/// light), outlined = the second one.
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.onTap,
    required this.filled,
    required this.brightness,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;
  final Brightness brightness;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final bool dark = brightness == Brightness.dark;
    final Color ink = AppStyle.inkFor(brightness);
    final Color fill = filled ? (dark ? AppStyle.white : ink) : AppStyle.transparent;
    final Color text = filled ? (dark ? AppStyle.black : AppStyle.white) : ink;
    return Material(
      color: fill,
      shape: StadiumBorder(
        side: filled
            ? BorderSide.none
            : BorderSide(color: AppStyle.secondaryInkFor(brightness)),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: SizedBox(
          height: 56.r,
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: text, size: 22.r),
                10.horizontalSpace,
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyle.interSemi(size: 17, color: text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The legal line in the card's own colours, translated, linking the
/// corporate_sdk terms and privacy pages.
class _CardTermsLine extends StatelessWidget {
  const _CardTermsLine({required this.slots, required this.color});

  final LoginEmbeddedSlots slots;
  final Color color;

  void _open(BuildContext context, Widget page) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => page),
      );

  @override
  Widget build(BuildContext context) {
    final TextStyle plain =
        AppStyle.interRegular(size: 14, color: color).copyWith(height: 1.5);
    final TextStyle link = plain.copyWith(
      decoration: TextDecoration.underline,
    );
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        Text('${AppHelpers.getTranslation(LoginCardEntry.termsLeadKey)} ',
            style: plain),
        InkWell(
          onTap: () => _open(context, slots.termPage!),
          child: Text(AppHelpers.getTranslation(TrKeys.terms), style: link),
        ),
        Text(' & ', style: plain),
        InkWell(
          onTap: () => _open(context, slots.policyPage!),
          child: Text(
            AppHelpers.getTranslation(TrKeys.privacyPolicy),
            style: link,
          ),
        ),
      ],
    );
  }
}
