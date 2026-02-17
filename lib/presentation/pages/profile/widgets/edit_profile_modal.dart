import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

import '../../../../application/providers.dart';
import '../../../../infrastructure/services/services.dart';
import '../../../component/components.dart';
import '../../../component/loading.dart';
import '../../../styles/style.dart';
import '../edit_car.dart';

class EditProfileModal extends ConsumerStatefulWidget {
  const EditProfileModal({super.key});

  @override
  ConsumerState<EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends ConsumerState<EditProfileModal> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(profileSettingsProvider.notifier)
          .fetchProfileDetails(
            context: context,
            checkYourNetwork: () {
              AppHelpers.showCheckTopSnackBar(
                context,
                AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
              );
            },
            setImage: (url) {
              ref.read(profileImageProvider.notifier).setUrl(url);
            },
            setUserData: (user) {
              ref.read(profileEditProvider.notifier).setInitialInfo(user);
            },
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileSettingsProvider);
    return state.isLoading || state.userData == null
        ? Padding(
            padding: REdgeInsets.symmetric(vertical: 30),
            child: const Loading(),
          )
        : KeyboardDisable(
            child: Consumer(
              builder: (context, ref, child) {
                final editState = ref.watch(profileEditProvider);
                final editNotifier = ref.read(profileEditProvider.notifier);
                return ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Column(
                        children: [
                          TitleAndIcon(
                            title: AppHelpers.getTranslation(
                              TrKeys.profileSettings,
                            ),
                          ),
                          24.verticalSpace,
                          Row(
                            children: [
                              Consumer(
                                builder: (context, ref, child) {
                                  final imageState = ref.watch(
                                    profileImageProvider,
                                  );
                                  return Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      ShopAvatar(
                                        radius: 16,
                                        imageUrl: imageState.imageUrl,
                                        path: imageState.path,
                                        size: 50,
                                        padding: 6,
                                        bgColor: Style.black.withValues(
                                          alpha: 0.27,
                                        ),
                                      ),
                                      Container(
                                        width: 50.r,
                                        height: 50.r,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            16.r,
                                          ),
                                          color: Style.black.withValues(
                                            alpha: 0.27,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          FlutterRemix.camera_fill,
                                          color: Style.white,
                                          size: 20.r,
                                        ),
                                        onPressed: () async {
                                          final XFile? pickedFile =
                                              await ImagePicker().pickImage(
                                                source: ImageSource.gallery,
                                                maxWidth: 1000,
                                                maxHeight: 1000,
                                                imageQuality: 90,
                                              );
                                          if (pickedFile != null) {
                                            // ignore: use_build_context_synchronously
                                            ref
                                                .read(
                                                  profileImageProvider.notifier,
                                                )
                                                .changePhoto(
                                                  // ignore: use_build_context_synchronously
                                                  context: context,
                                                  path: pickedFile.path,
                                                  firstname:
                                                      state.userData?.firstname,
                                                );
                                          }
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                              16.horizontalSpace,
                              Expanded(
                                child: UnderlinedBorderTextField(
                                  label: AppHelpers.getTranslation(
                                    TrKeys.firstname,
                                  ),
                                  initialText: editState.firstname,
                                  onChanged: editNotifier.setFirstname,
                                  descriptionText: editState.isFirstnameError
                                      ? AppHelpers.getTranslation(
                                          TrKeys.firstnameCannotBeEmpty,
                                        )
                                      : null,
                                  isError: editState.isFirstnameError,
                                ),
                              ),
                            ],
                          ),
                          24.verticalSpace,
                          UnderlinedBorderTextField(
                            label: AppHelpers.getTranslation(TrKeys.lastname),
                            initialText: editState.lastname,
                            onChanged: editNotifier.setLastname,
                            descriptionText: editState.isLastnameError
                                ? AppHelpers.getTranslation(
                                    TrKeys.lastnameCannotBeEmpty,
                                  )
                                : null,
                            isError: editState.isLastnameError,
                          ),
                          24.verticalSpace,
                          if (!AppConstants.isSpecificNumberEnabled)
                            UnderlinedBorderTextField(
                              label: AppHelpers.getTranslation(
                                TrKeys.phoneNumber,
                              ),
                              initialText: editState.phone,
                              inputType: TextInputType.phone,
                              readOnly: !editState.isPhoneEditable,
                              onChanged: editNotifier.setPhone,
                            ),
                          if (AppConstants.isSpecificNumberEnabled)
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: IntlPhoneField(
                                showCountryFlag: AppConstants.showFlag,
                                showDropdownIcon: AppConstants.showArrowIcon,
                                disableLengthCheck:
                                    !AppConstants.isNumberLengthAlwaysSame,
                                onChanged: (phoneNum) => editNotifier.setPhone(
                                  phoneNum.completeNumber,
                                ),
                                validator: (s) {
                                  if (AppConstants.isNumberLengthAlwaysSame &&
                                      (s?.isValidNumber() ?? false)) {
                                    return AppHelpers.getTranslation(
                                      TrKeys.phoneNumberIsNotValid,
                                    );
                                  }
                                  return null;
                                },
                                keyboardType: TextInputType.number,
                                autovalidateMode: AutovalidateMode.disabled,
                                initialCountryCode: PhoneNumber.fromCompleteNumber(
                                  completeNumber:
                                      "+${editState.phone.replaceAll('+', "")}",
                                ).countryISOCode,
                                initialValue: PhoneNumber.fromCompleteNumber(
                                  completeNumber:
                                      "+${editState.phone.replaceAll('+', "")}",
                                ).number,
                                enabled: editState.isPhoneEditable,
                                invalidNumberMessage: AppHelpers.getTranslation(
                                  TrKeys.phoneNumberIsNotValid,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                textAlignVertical: TextAlignVertical.center,
                                decoration: InputDecoration(
                                  counterText: '',
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide.merge(
                                      const BorderSide(
                                        color: Style.borderColor,
                                      ),
                                      const BorderSide(
                                        color: Style.borderColor,
                                      ),
                                    ),
                                  ),
                                  errorBorder: UnderlineInputBorder(
                                    borderSide: BorderSide.merge(
                                      const BorderSide(
                                        color: Style.borderColor,
                                      ),
                                      const BorderSide(
                                        color: Style.borderColor,
                                      ),
                                    ),
                                  ),
                                  border: const UnderlineInputBorder(),
                                  focusedErrorBorder:
                                      const UnderlineInputBorder(),
                                  disabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide.merge(
                                      const BorderSide(
                                        color: Style.borderColor,
                                      ),
                                      const BorderSide(
                                        color: Style.borderColor,
                                      ),
                                    ),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(),
                                ),
                              ),
                            ),
                          24.verticalSpace,
                          UnderlinedBorderTextField(
                            label: AppHelpers.getTranslation(TrKeys.email),
                            initialText: editState.email,
                            inputType: TextInputType.emailAddress,
                            readOnly: !editState.isEmailEditable,
                            onChanged: editNotifier.setEmail,
                          ),
                          24.verticalSpace,
                          UnderlinedBorderTextField(
                            label: AppHelpers.getTranslation(TrKeys.password),
                            obscure: editState.showPassword,
                            onChanged: editNotifier.setPassword,
                            isError: editState.isPasswordError,
                            descriptionText: editState.isPasswordError
                                ? AppHelpers.getTranslation(
                                    TrKeys
                                        .passwordShouldContainMinimum6Characters,
                                  )
                                : null,
                            suffixIcon: IconButton(
                              splashRadius: 25,
                              icon: Icon(
                                editState.showPassword
                                    ? FlutterRemix.eye_line
                                    : FlutterRemix.eye_close_line,
                                color: Style.black,
                                size: 20.r,
                              ),
                              onPressed: editNotifier.toggleShowPassword,
                            ),
                          ),
                          24.verticalSpace,
                          UnderlinedBorderTextField(
                            label: AppHelpers.getTranslation(
                              TrKeys.confirmPassword,
                            ),
                            obscure: editState.showConfirmPassword,
                            onChanged: editNotifier.setConfirmPassword,
                            isError: editState.isConfirmPasswordError,
                            descriptionText: editState.isConfirmPasswordError
                                ? AppHelpers.getTranslation(
                                    TrKeys
                                        .confirmPasswordDoesntMatchWithNewPassword,
                                  )
                                : null,
                            suffixIcon: IconButton(
                              splashRadius: 25.r,
                              icon: Icon(
                                editState.showConfirmPassword
                                    ? FlutterRemix.eye_line
                                    : FlutterRemix.eye_close_line,
                                color: Style.black,
                                size: 20.r,
                              ),
                              onPressed: editNotifier.toggleShowConfirmPassword,
                            ),
                          ),
                        ],
                      ),
                    ),
                    24.verticalSpace,
                    const Divider(),
                    GestureDetector(
                      onTap: () {
                        AppHelpers.showCustomModalBottomSheet(
                          paddingTop: 120.h,
                          context: context,
                          modal: const EditCar(),
                          isDarkMode: false,
                          isExpanded: true,
                        );
                      },
                      child: Container(
                        color: Style.transparent,
                        child: Padding(
                          padding: EdgeInsets.all(16.r),
                          child: Row(
                            children: [
                              Icon(FlutterRemix.time_fill, size: 20.r),
                              8.horizontalSpace,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppHelpers.getTranslation(
                                      TrKeys.deliveryVehicle,
                                    ),
                                    style: Style.interNormal(
                                      size: 12.sp,
                                      color: Style.black,
                                    ),
                                  ),
                                  Text(
                                    "${LocalStorage.getDeliveryInfo()?.data?.number ?? ''} — ${LocalStorage.getDeliveryInfo()?.data?.model ?? ''}, ${LocalStorage.getDeliveryInfo()?.data?.color ?? ''}",
                                    style: Style.interNormal(
                                      size: 12.sp,
                                      color: Style.black,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const Icon(FlutterRemix.arrow_right_s_line),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Divider(),
                    Padding(
                      padding: EdgeInsets.all(16.r),
                      child: CustomButton(
                        title: AppHelpers.getTranslation(TrKeys.save),
                        isLoading: editState.isLoading,
                        onPressed: () {
                          editNotifier.updateGeneralInfo(
                            context: context,
                            checkYourNetwork: () {
                              AppHelpers.showCheckTopSnackBar(
                                context,
                                AppHelpers.getTranslation(
                                  TrKeys.checkYourNetworkConnection,
                                ),
                              );
                            },
                            updated: context.router.maybePop,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          );
  }
}
