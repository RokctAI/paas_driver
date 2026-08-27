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

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:base_sdk/src/models/data/user.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/app_bars/app_bar_bottom_sheet.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/keyboard_dismisser.dart';
import 'package:base_sdk/src/presentation/components/text_fields/outline_bordered_text_field.dart';
import 'package:auth_sdk/src/common/presentation/pages/auth/confirmation/register_confirmation_page.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';
import 'package:auth_sdk/src/common/application/auth/auth.dart';

@RoutePage()
class ResetPasswordPage extends ConsumerWidget {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(resetPasswordProvider.notifier);
    final state = ref.watch(resetPasswordProvider);
    final bool isDarkMode = LocalStorage.getAppThemeMode();
    final bool isLtr = LocalStorage.getLangLtr();
    ref.listen(resetPasswordProvider, (previous, next) {
      if (previous!.isSuccess != next.isSuccess && next.isSuccess) {
        Navigator.pop(context);
        AppHelpers.showCustomModalBottomSheet(
          context: context,
          modal: RegisterConfirmationPage(
            verificationId: next.verifyId,
            userModel: UserModel(email: state.email),
            isResetPassword: true,
          ),
          isDarkMode: isDarkMode,
        );
      }
    });
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
                        Text(
                          AppHelpers.getTranslation(TrKeys.resetPasswordText),
                          style: AppStyle.interRegular(
                            size: 14.sp,
                            color: AppStyle.textDarkSecondary,
                          ),
                        ),
                        40.verticalSpace,
                        if (AppConstants.signUpType == SignUpType.phone)
                          Directionality(
                            textDirection:
                                isLtr ? TextDirection.ltr : TextDirection.rtl,
                            child: IntlPhoneField(
                              style: TextStyle(color: AppStyle.textPrimary),
                              dropdownTextStyle:
                                  TextStyle(color: AppStyle.textPrimary),
                              disableLengthCheck:
                                  !AppConstants.isNumberLengthAlwaysSame,
                              onChanged: (phoneNum) {
                                notifier.setEmail(phoneNum.completeNumber);
                              },
                              validator: (s) {
                                if (AppConstants.isNumberLengthAlwaysSame &&
                                    (s?.isValidNumber() ?? true)) {
                                  return AppHelpers.getTranslation(
                                    TrKeys.phoneNumberIsNotValid,
                                  );
                                }
                                return null;
                              },
                              keyboardType: TextInputType.phone,
                              initialCountryCode: AppConstants.countryCodeISO,
                              invalidNumberMessage: AppHelpers.getTranslation(
                                TrKeys.phoneNumberIsNotValid,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              showCountryFlag: AppConstants.showFlag,
                              showDropdownIcon: AppConstants.showArrowIcon,
                              autovalidateMode:
                                  AppConstants.isNumberLengthAlwaysSame
                                      ? AutovalidateMode.onUserInteraction
                                      : AutovalidateMode.disabled,
                              textAlignVertical: TextAlignVertical.center,
                              decoration: InputDecoration(
                                counterText: '',
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide.merge(
                                    const BorderSide(
                                      color: AppStyle.differBorderColor,
                                    ),
                                    const BorderSide(
                                      color: AppStyle.differBorderColor,
                                    ),
                                  ),
                                ),
                                errorBorder: UnderlineInputBorder(
                                  borderSide: BorderSide.merge(
                                    const BorderSide(
                                      color: AppStyle.differBorderColor,
                                    ),
                                    const BorderSide(
                                      color: AppStyle.differBorderColor,
                                    ),
                                  ),
                                ),
                                border: const UnderlineInputBorder(),
                                focusedErrorBorder:
                                    const UnderlineInputBorder(),
                                disabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide.merge(
                                    const BorderSide(
                                      color: AppStyle.differBorderColor,
                                    ),
                                    const BorderSide(
                                      color: AppStyle.differBorderColor,
                                    ),
                                  ),
                                ),
                                focusedBorder: const UnderlineInputBorder(),
                              ),
                            ),
                          ),
                        if (AppConstants.signUpType == SignUpType.both)
                          OutlinedBorderTextField(
                            label: AppHelpers.getTranslation(
                              TrKeys.emailOrPhoneNumber,
                            ).toUpperCase(),
                            onChanged: notifier.setEmail,
                            isError: !state.isSuccess,
                            descriptionText: AppHelpers.getTranslation(
                              TrKeys.canNotBeEmpty,
                            ),
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
                          if (AppConstants.isPhoneFirebase) {
                            notifier.checkEmail()
                                ? notifier.sendCode(context)
                                : notifier.sendCodeToNumber(context);
                          } else {
                            notifier.sendCode(context);
                          }
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
