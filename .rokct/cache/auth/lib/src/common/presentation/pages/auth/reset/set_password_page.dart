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
import 'package:auth_sdk/src/common/application/auth/auth.dart';
import 'package:base_sdk/src/presentation/components/keyboard_dismisser.dart';

class SetPasswordPage extends ConsumerWidget {
  const SetPasswordPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(resetPasswordProvider.notifier);
    final state = ref.watch(resetPasswordProvider);
    final bool isLtr = LocalStorage.getLangLtr();
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: AbsorbPointer(
        absorbing: state.isLoading,
        child: KeyboardDismisser(
          child: Container(
            padding: MediaQuery.of(context).viewInsets,
            decoration: BoxDecoration(
              color: AppStyle.surfaceDark,
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
