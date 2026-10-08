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
import 'package:remixicon/remixicon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/app_bars/app_bar_bottom_sheet.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/text_fields/outline_bordered_text_field.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
// The reset-password provider directly, not the auth barrel: the barrel
// also exports the register-confirmation provider, and pulling that in
// drags OfflineAuthService into this library, whose drift accessors only
// exist once the composer has injected auth_sdk's table into base_sdk's
// @DriftDatabase. This sheet only ever needed resetPasswordProvider, and
// importing it on its own is what lets a widget test mount this page.
import 'package:auth_sdk/src/common/application/auth/reset_password/reset_password_provider.dart';
import 'package:base_sdk/src/presentation/components/keyboard_dismisser.dart';

class SetPasswordPage extends ConsumerWidget {
  const SetPasswordPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(resetPasswordProvider.notifier);
    final state = ref.watch(resetPasswordProvider);
    final bool isLtr = LocalStorage.getLangLtr();
    // A BuildContext lookup for the mode, not the app-wide AppStyle.isDark
    // static behind AppStyle.surfaceDark (Ray, 2026-09-19: "glance doesnt
    // change test immediately untill you come back if you switched theme
    // mode" — the same defect, found here by the fleet audit that followed).
    //
    // This sheet resolved nothing from the context that a theme-mode flip
    // touches: its surface came from AppStyle's statics, and its only other
    // context reads are MediaQuery's view insets and safe-area padding,
    // neither of which changes with the mode. A mutable static is not an
    // inherited widget, so the flip scheduled no rebuild of this element and
    // the sheet kept the previous mode's background while it stayed open —
    // and it stays open for as long as it takes to type a new password
    // twice. The resetPasswordProvider it watches is a feature notifier that
    // a theme-mode change never notifies, so that is no rebuild trigger
    // either. Reading the inherited theme here makes this element a
    // dependent, so the mode change itself restyles the sheet in place.
    final Brightness brightness = Theme.of(context).brightness;
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: AbsorbPointer(
        absorbing: state.isLoading,
        child: KeyboardDismisser(
          child: Container(
            padding: MediaQuery.of(context).viewInsets,
            decoration: BoxDecoration(
              color: AppStyle.surfaceFor(brightness),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
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
                          title: AppHelpers.getTranslation(
                            TrKeys.resetPassword,
                          ),
                        ),
                        40.verticalSpace,
                        OutlinedBorderTextField(
                          label: AppHelpers.getTranslation(
                            TrKeys.password,
                          ).toUpperCase(),
                          obscure: state.showPassword,
                          suffixIcon: IconButton(
                            splashRadius: 25,
                            icon: Icon(
                              state.showPassword
                                  ? Remix.eye_line
                                  : Remix.eye_close_line,
                              size: 20.r,
                            ),
                            onPressed: () => notifier.toggleShowPassword(),
                          ),
                          onChanged: (name) => notifier.setPassword(name),
                          isError: state.isPasswordInvalid,
                          descriptionText: state.isPasswordInvalid
                              ? AppHelpers.getTranslation(
                                  TrKeys
                                      .passwordShouldContainMinimum8Characters,
                                )
                              : null,
                        ),
                        34.verticalSpace,
                        OutlinedBorderTextField(
                          label: AppHelpers.getTranslation(
                            TrKeys.password,
                          ).toUpperCase(),
                          obscure: state.showConfirmPassword,
                          suffixIcon: IconButton(
                            splashRadius: 25,
                            icon: Icon(
                              state.showConfirmPassword
                                  ? Remix.eye_line
                                  : Remix.eye_close_line,
                              size: 20.r,
                            ),
                            onPressed: () =>
                                notifier.toggleShowConfirmPassword(),
                          ),
                          onChanged: (name) =>
                              notifier.setConfirmPassword(name),
                          isError: state.isConfirmPasswordInvalid,
                          descriptionText: state.isConfirmPasswordInvalid
                              ? AppHelpers.getTranslation(
                                  TrKeys.confirmPasswordIsNotTheSame,
                                )
                              : null,
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.paddingOf(context).bottom,
                        top: 120.h,
                      ),
                      child: CustomButton(
                        isLoading: state.isLoading,
                        title: AppHelpers.getTranslation(TrKeys.send),
                        onPressed: () {
                          notifier.setResetPassword(context);
                        },
                        background: AppStyle.primary,
                        textColor: AppStyle.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
