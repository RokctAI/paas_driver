import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../../../../styles/style.dart';
import '../../../../component/components.dart';
import '../../../../routes/app_router.gr.dart';
import '../../../../../application/providers.dart';
import '../../../../../infrastructure/services/services.dart';

class LoginModal extends ConsumerStatefulWidget {
  const LoginModal({super.key});

  @override
  ConsumerState<LoginModal> createState() => _LoginModalState();
}

class _LoginModalState extends ConsumerState<LoginModal> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final event = ref.read(loginProvider.notifier);
    final state = ref.watch(loginProvider);
    final bool isDarkMode = LocalStorage.getAppThemeMode();
    final bool isLtr = LocalStorage.getLangLtr();
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: AbsorbPointer(
        absorbing: state.isLoading,
        child: KeyboardDisable(
          child: Container(
            margin: MediaQuery.viewInsetsOf(context),
            decoration: BoxDecoration(
              color: Style.greyColor.withOpacity(0.96),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            width: double.infinity,
            child: Padding(
              padding: REdgeInsets.all(16.0),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Column(
                      children: [
                        AppBarBottomSheet(
                          title: AppHelpers.getTranslation(TrKeys.login),
                        ),
                        20.verticalSpace,
                        if (AppConstants.isSpecificNumberEnabled)
                          Directionality(
                            textDirection:
                                isLtr ? TextDirection.ltr : TextDirection.rtl,
                            child: IntlPhoneField(
                              disableLengthCheck:
                                  !AppConstants.isNumberLengthAlwaysSame,
                              onChanged: (phoneNum) {
                                event.setEmail(phoneNum.completeNumber);
                              },
                              validator: (s) {
                                if (state.isLoginError) {
                                  return AppHelpers.getTranslation(
                                      TrKeys.loginCredentialsAreNotValid);
                                }
                                if (AppConstants.isNumberLengthAlwaysSame &&
                                    (s?.isValidNumber() ?? true)) {
                                  return AppHelpers.getTranslation(
                                      TrKeys.phoneNumberIsNotValid);
                                }
                                return null;
                              },
                              keyboardType: TextInputType.phone,
                              initialCountryCode: AppConstants.countryCodeISO,
                              invalidNumberMessage: AppHelpers.getTranslation(
                                  state.isLoginError
                                      ? TrKeys.loginCredentialsAreNotValid
                                      : TrKeys.phoneNumberIsNotValid),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              showCountryFlag: AppConstants.showFlag,
                              showDropdownIcon: AppConstants.showArrowIcon,
                              autovalidateMode: state.isLoginError
                                  ? AutovalidateMode.always
                                  : AppConstants.isNumberLengthAlwaysSame
                                      ? AutovalidateMode.onUserInteraction
                                      : AutovalidateMode.disabled,
                              textAlignVertical: TextAlignVertical.center,
                              decoration: InputDecoration(
                                counterText: '',
                                enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide.merge(
                                        const BorderSide(
                                            color: Style.differBorderColor),
                                        const BorderSide(
                                            color: Style.differBorderColor))),
                                errorBorder: UnderlineInputBorder(
                                    borderSide: BorderSide.merge(
                                        const BorderSide(
                                            color: Style.differBorderColor),
                                        const BorderSide(
                                            color: Style.differBorderColor))),
                                border: const UnderlineInputBorder(),
                                focusedErrorBorder:
                                    const UnderlineInputBorder(),
                                disabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide.merge(
                                        const BorderSide(
                                            color: Style.differBorderColor),
                                        const BorderSide(
                                            color: Style.differBorderColor))),
                                focusedBorder: const UnderlineInputBorder(),
                              ),
                            ),
                          ),
                        if (!AppConstants.isSpecificNumberEnabled)
                          UnderlinedBorderTextField(
                            inputType: TextInputType.emailAddress,
                            textCapitalization: TextCapitalization.none,
                            textController: emailController,
                            textInputAction: TextInputAction.next,
                            label:
                                AppHelpers.getTranslation(TrKeys.emailOrPhone)
                                    .toUpperCase(),
                            onChanged: event.setEmail,
                            isError:
                                state.isEmailNotValid || state.isLoginError,
                            descriptionText: state.isLoginError
                                ? AppHelpers.getTranslation(
                                    TrKeys.loginCredentialsAreNotValid)
                                : (state.isEmailNotValid
                                    ? AppHelpers.getTranslation(
                                        TrKeys.cannotBeEmpty)
                                    : null),
                          ),
                        34.verticalSpace,
                        UnderlinedBorderTextField(
                          textInputAction: TextInputAction.done,
                          textCapitalization: TextCapitalization.none,
                          label: AppHelpers.getTranslation(TrKeys.password)
                              .toUpperCase(),
                          obscure: state.showPassword,
                          textController: passwordController,
                          suffixIcon: ButtonsBouncingEffect(
                            child: GestureDetector(
                              onTap: event.toggleShowPassword,
                              child: Icon(
                                state.showPassword
                                    ? FlutterRemix.eye_line
                                    : FlutterRemix.eye_close_line,
                                color: isDarkMode
                                    ? Style.blackColor
                                    : Style.textColor,
                                size: 20.r,
                              ),
                            ),
                          ),
                          onChanged: event.setPassword,
                          isError:
                              state.isPasswordNotValid || state.isLoginError,
                          descriptionText: state.isLoginError
                              ? AppHelpers.getTranslation(
                                  TrKeys.loginCredentialsAreNotValid)
                              : (state.isPasswordNotValid
                                  ? AppHelpers.getTranslation(TrKeys
                                      .passwordShouldContainMinimum8Characters)
                                  : null),
                        ),
                        30.verticalSpace,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  height: 20.h,
                                  width: 20.w,
                                  child: Checkbox(
                                    side: BorderSide(
                                      color: Style.blackColor,
                                      width: 2.r,
                                    ),
                                    activeColor: Style.blackColor,
                                    value: state.isKeepLogin,
                                    onChanged: (value) =>
                                        event.toggleKeepLogin(),
                                  ),
                                ),
                                8.horizontalSpace,
                                Text(
                                  AppHelpers.getTranslation(TrKeys.keepLogged),
                                  style: Style.interNormal(
                                    size: 12.sp,
                                    color: Style.blackColor,
                                  ),
                                ),
                              ],
                            ),
                            // ForgotTextButton(
                            //   title: AppHelpers.getTranslation(
                            //     TrKeys.forgotPassword,
                            //   ),
                            //   onPressed: () {
                            //     // TODO forgetPassword
                            //     context.router.maybePop();
                            //     AppHelpers
                            //         .showCustomModalBottomSheetWithoutIosIcon(
                            //       context: context,
                            //       modal: const ResetPasswordPage(),
                            //       isDarkMode: isDarkMode,
                            //     );
                            //   },
                            // ),
                          ],
                        ),
                      ],
                    ),
                    40.verticalSpace,
                    Column(
                      children: [
                        CustomButton(
                          title: AppHelpers.getTranslation(TrKeys.login),
                          isLoading: state.isLoading,
                          onPressed: () {
                            event.login(
                              context: context,
                              checkYourNetwork: () {
                                AppHelpers.showCheckTopSnackBar(
                                  context,
                                  AppHelpers.getTranslation(
                                      TrKeys.checkYourNetworkConnection),
                                );
                              },
                              loginSuccess: () {
                                ref
                                    .read(splashProvider.notifier)
                                    .fetchDriverDetails(context: context);
                                Navigator.pop(context);
                                context.router.popUntilRoot();
                                context.replaceRoute(const HomeRoute());
                              },
                              youAreNotDeliveryman: () {
                                context.replaceRoute(const BecomeDriverRoute());
                              },
                            );
                          },
                        ),
                        32.verticalSpace,
                        AppConstants.isDemo
                            ? Column(
                                children: [
                                  Row(
                                    children: <Widget>[
                                      const Expanded(
                                        child:
                                            Divider(color: Style.shimmerBase),
                                      ),
                                      Padding(
                                        padding: REdgeInsets.symmetric(
                                            horizontal: 12),
                                        child: Text(
                                          AppHelpers.getTranslation(
                                              TrKeys.demoLoginPassword),
                                          style: Style.interNormal(
                                            size: 12.sp,
                                            color: Style.textColor,
                                          ),
                                        ),
                                      ),
                                      const Expanded(
                                        child:
                                            Divider(color: Style.shimmerBase),
                                      ),
                                    ],
                                  ),
                                  22.verticalSpace,
                                  InkWell(
                                    onTap: () {
                                      emailController.text =
                                          AppConstants.demoSellerLogin;
                                      passwordController.text =
                                          AppConstants.demoSellerPassword;
                                      event.setEmail(
                                          AppConstants.demoSellerLogin);
                                      event.setPassword(
                                          AppConstants.demoSellerPassword);
                                    },
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            text:
                                                '${AppHelpers.getTranslation(TrKeys.login)}:',
                                            style: Style.interNormal(
                                                letterSpacing: -0.3),
                                            children: [
                                              TextSpan(
                                                text:
                                                    ' ${AppConstants.demoSellerLogin}',
                                                style: Style.interRegular(
                                                  letterSpacing: -0.3,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                        6.verticalSpace,
                                        RichText(
                                          text: TextSpan(
                                            text:
                                                '${AppHelpers.getTranslation(TrKeys.password)}:',
                                            style: Style.interNormal(
                                                letterSpacing: -0.3),
                                            children: [
                                              TextSpan(
                                                text:
                                                    ' ${AppConstants.demoSellerPassword}',
                                                style: Style.interRegular(
                                                  letterSpacing: -0.3,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                        22.verticalSpace,
                      ],
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
