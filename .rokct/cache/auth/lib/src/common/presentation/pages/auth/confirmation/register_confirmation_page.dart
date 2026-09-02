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

// ignore_for_file: unused_result

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/application/edit_profile/edit_profile_provider.dart';
import 'package:base_sdk/src/application/profile/profile_provider.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/app_bars/app_bar_bottom_sheet.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/keyboard_dismisser.dart';
import 'package:auth_sdk/src/common/presentation/pages/auth/reset/set_password_page.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';
import 'package:auth_sdk/src/common/application/auth/auth.dart';
import 'package:auth_sdk/src/common/presentation/pages/auth/register/register_page.dart';

@RoutePage()
class RegisterConfirmationPage extends ConsumerStatefulWidget {
  final UserModel userModel;
  final bool isResetPassword;
  final String verificationId;
  final bool editPhone;

  /// Deferred-OTP mode (PendingOtpGate): the account already exists on the
  /// backend — verification only lifts its unverified-account limit. On
  /// verify success the sheet just closes instead of continuing into the
  /// registration form, and phone codes go through the backend
  /// sendOtp/verifyPhone pair even when AppConstants.isPhoneFirebase.
  final bool isDeferredOtp;

  const RegisterConfirmationPage({
    super.key,
    required this.userModel,
    this.isResetPassword = false,
    required this.verificationId,
    this.editPhone = false,
    this.isDeferredOtp = false,
  });

  @override
  ConsumerState<RegisterConfirmationPage> createState() =>
      _RegisterConfirmationPageState();
}

class _RegisterConfirmationPageState
    extends ConsumerState<RegisterConfirmationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.refresh(registerConfirmationProvider);
      ref.read(registerConfirmationProvider.notifier).startTimer();
    });
  }

  @override
  void deactivate() {
    ref.read(registerConfirmationProvider.notifier).disposeTimer();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(registerConfirmationProvider.notifier);
    final state = ref.watch(registerConfirmationProvider);
    final bool isDarkMode = LocalStorage.getAppThemeMode();
    final bool isLtr = LocalStorage.getLangLtr();
    ref.listen(registerConfirmationProvider, (previous, next) {
      if (previous!.isSuccess != next.isSuccess && next.isSuccess) {
        if (widget.isDeferredOtp) {
          // Deferred flow: the account is already registered — verification
          // is the whole job, so just close the sheet and let the user
          // carry on where they were. (Verify success already cleared the
          // pending_otp_verification flag, so the gate won't re-prompt.)
          Navigator.pop(context);
          return;
        }
        Navigator.pop(context);
        AppHelpers.showCustomModalBottomSheet(
          context: context,
          modal: RegisterPage(isOnlyEmail: false),
          isDarkMode: isDarkMode,
        );
      }
      if (previous.isResetPasswordSuccess != next.isResetPasswordSuccess &&
          next.isResetPasswordSuccess) {
        Navigator.pop(context);
        AppHelpers.showCustomModalBottomSheet(
          context: context,
          modal: const SetPasswordPage(),
          isDarkMode: isDarkMode,
        );
      }
    });
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: AbsorbPointer(
        absorbing: state.isLoading || state.isResending,
        child: KeyboardDismisser(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              margin: MediaQuery.of(context).viewInsets,
              decoration: BoxDecoration(
                color: AppStyle.surfaceDark,
                borderRadius: BorderRadius.all(Radius.circular(40.r)),
              ),
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        children: [
                          AppBarBottomSheet(
                            title: AppHelpers.getTranslation(TrKeys.enterOtp),
                          ),
                          Text(
                            AppHelpers.getTranslation(TrKeys.sendOtp),
                            style: AppStyle.interRegular(
                              size: 14,
                              color: AppStyle.textDarkSecondary,
                            ),
                          ),
                          Text(
                            widget.userModel.email ?? "",
                            style: AppStyle.interRegular(
                              size: 14,
                              color: AppStyle.textDarkSecondary,
                            ),
                          ),
                          40.verticalSpace,
                          SizedBox(
                            height: 64,
                            child: PinFieldAutoFill(
                              codeLength: 6,
                              currentCode: state.confirmCode,
                              onCodeChanged: notifier.setCode,
                              cursor: Cursor(
                                width: 1,
                                height: 24,
                                color: isDarkMode
                                    ? AppStyle.white
                                    : AppStyle.black,
                                enabled: true,
                              ),
                              decoration: BoxLooseDecoration(
                                gapSpace: 10.r,
                                textStyle: AppStyle.interNormal(
                                  size: 15.sp,
                                  color: isDarkMode
                                      ? AppStyle.white
                                      : AppStyle.black,
                                ),
                                bgColorBuilder: FixedColorBuilder(
                                  isDarkMode
                                      ? AppStyle.mainBackDark
                                      : AppStyle.transparent,
                                ),
                                strokeColorBuilder: FixedColorBuilder(
                                  state.isCodeError
                                      ? AppStyle.red
                                      : isDarkMode
                                          ? AppStyle.borderDark
                                          : AppStyle.outlineButtonBorder,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.paddingOf(context).bottom,
                          top: 120.h,
                        ),
                        // Same clamped-sheet fix as the register form's
                        // name row: flex the resend/confirm pair (1:2, 8px
                        // gap) against the SHEET's width — the old
                        // window-width thirds overflowed the width-clamped
                        // bottom sheet on wide windows. Pixel-identical on
                        // phones, where the sheet spans the window.
                        child: Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                              isLoading: state.isResending,
                              title: state.isTimeExpired
                                  ? AppHelpers.getTranslation(TrKeys.resendOtp)
                                  : state.timerText,
                              onPressed: () {
                                if (state.isTimeExpired) {
                                  if (widget.isResetPassword) {
                                    widget.verificationId.isEmpty
                                        ? notifier.resendConfirmation(
                                            context,
                                            widget.userModel.email ?? "",
                                            isResetPassword:
                                                widget.isResetPassword,
                                          )
                                        : notifier.resendResetConfirmation(
                                            context,
                                            widget.userModel.email ?? "",
                                          );
                                    return;
                                  } else {
                                    widget.verificationId.isEmpty
                                        ? notifier.resendConfirmation(
                                            context,
                                            widget.userModel.email ?? "",
                                            isResetPassword:
                                                widget.isResetPassword,
                                            isDeferredOtp:
                                                widget.isDeferredOtp,
                                          )
                                        : notifier.sendCodeToNumber(
                                            context,
                                            widget.userModel.email ?? "",
                                            useBackendOtp:
                                                widget.isDeferredOtp,
                                          );
                                  }
                                  notifier.startTimer();
                                }
                              },
                              background: AppStyle.primary,
                              textColor: AppStyle.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: CustomButton(
                              isLoading: state.isLoading,
                              title: AppHelpers.getTranslation(
                                TrKeys.confirmation,
                              ),
                              onPressed: () {
                                if (state.confirmCode.length == 6) {
                                  if (widget.isResetPassword) {
                                    widget.verificationId.isEmpty
                                        ? notifier.confirmCodeResetPassword(
                                            context,
                                            widget.userModel.email ?? "",
                                          )
                                        : notifier
                                            .confirmCodeResetPasswordWithPhone(
                                            context,
                                            widget.userModel.email ?? "",
                                            widget.verificationId,
                                          );
                                  } else {
                                    widget.verificationId.isEmpty
                                        ? notifier.confirmCode(
                                            context,
                                            ref,
                                            isDeferredOtp:
                                                widget.isDeferredOtp,
                                          ) // Pass ref here
                                        : notifier.confirmCodeWithPhone(
                                            context: context,
                                            verificationId:
                                                widget.verificationId,
                                            ref: ref, // Pass ref here
                                            useBackendOtp:
                                                widget.isDeferredOtp,
                                            isDeferredOtp:
                                                widget.isDeferredOtp,
                                            onSuccess: widget.editPhone
                                                ? () {
                                                    if (widget.editPhone) {
                                                      ref
                                                          .read(
                                                            editProfileProvider
                                                                .notifier,
                                                          )
                                                          .editProfile(
                                                            context,
                                                            ProfileData(
                                                              phone: widget
                                                                  .userModel
                                                                  .email,
                                                              firstname: ref
                                                                      .watch(
                                                                        profileProvider,
                                                                      )
                                                                      .userData
                                                                      ?.firstname ??
                                                                  "",
                                                            ),
                                                          );
                                                      return;
                                                    }
                                                  }
                                                : null,
                                          );
                                  }
                                }
                              },
                              background: state.isConfirm
                                  ? AppStyle.primary
                                  : AppStyle.cardDark,
                              textColor: state.isConfirm
                                  ? AppStyle.black
                                  : AppStyle.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
