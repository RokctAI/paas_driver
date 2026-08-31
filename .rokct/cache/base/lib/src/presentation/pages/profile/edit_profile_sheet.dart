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

import 'dart:io';
import 'package:base_sdk/src/navigation/embedded_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' as intl;
import 'package:remixicon/remixicon.dart';
import 'package:base_sdk/src/application/edit_profile/edit_profile_provider.dart';
import 'package:base_sdk/src/application/profile/profile_provider.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/app_validators.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/custom_network_image.dart';
import 'package:base_sdk/src/presentation/components/keyboard_dismisser.dart';
import 'package:base_sdk/src/presentation/components/loading.dart';
import 'package:base_sdk/src/presentation/components/text_fields/outline_bordered_text_field.dart';
import 'package:base_sdk/src/presentation/components/text_fields/underline_drop_down.dart';
import 'package:base_sdk/src/presentation/components/title_icon.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

import 'package:base_sdk/src/constants/app_constants.dart';

/// The shared edit-own-details bottom sheet (approved frame 4d,
/// 2026-08-30 — chips 725-734).
///
/// Promoted verbatim from marketplace_sdk's customer
/// `EditProfileScreen` (edit_profile_page.dart) so EVERY host of
/// [GenericProfilePage] can wire the user-card edit pencil (chip 109,
/// `ProfileSectionRegistry.I.onEditProfile`) to the one shipped
/// edit-own-details flow: drag handle, "Profile settings" title, avatar
/// with the photo-change pencil, EMAIL (read-only once valid),
/// FIRSTNAME | SURNAME, PHONE NUMBER (read-only, phone-verify flow),
/// DATE OF BIRTH picker, GENDER dropdown, and Save — driven end to end
/// by base_sdk's own [editProfileProvider]
/// (EditProfileNotifier -> UserRepositoryFacade.editProfile -> the
/// self-scoped `update_user_profile` endpoint). No backend surface is
/// added here.
///
/// The only promotion adaptations (per the approved 4d captions): the
/// sheet chrome, light-only `bgGrey`@96% as shipped, now resolves the
/// dark equivalent through `AppStyle.isDark`; and the icon set is
/// base_sdk's `remixicon` (the glyph is unchanged: `Remix.pencil_line`).
/// Present it with `AppHelpers.showCustomModalBottomDragSheet(...,
/// modal: (c) => EditProfileScreen(controller: c))` — the same call the
/// customer app ships.
class EditProfileScreen extends ConsumerStatefulWidget {
  final ScrollController controller;

  const EditProfileScreen({super.key, required this.controller});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController birthDay;

  @override
  void initState() {
    birthDay = TextEditingController(
      text: intl.DateFormat("yyyy-MM-dd").format(
        DateTime.tryParse(
              ref.read(profileProvider).userData?.birthday ?? "",
            )?.toLocal() ??
            DateTime.now(),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      ref
          .read(editProfileProvider.notifier)
          .setPhone(ref.read(profileProvider).userData?.phone ?? "");
      ref.read(editProfileProvider.notifier).setBirth(
            intl.DateFormat("yyyy-MM-dd").format(
              DateTime.tryParse(
                    ref.read(profileProvider).userData?.birthday ?? "",
                  )?.toLocal() ??
                  DateTime.now(),
            ),
          );
    });
    super.initState();
  }

  @override
  void dispose() {
    birthDay.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLtr = LocalStorage.getLangLtr();
    final event = ref.read(editProfileProvider.notifier);
    final user = ref.watch(profileProvider).userData;
    final state = ref.watch(editProfileProvider);
    ref.listen(editProfileProvider, (previous, next) {
      if (next.isSuccess && (previous?.isSuccess ?? false) != next.isSuccess) {
        ref
            .read(profileProvider.notifier)
            .setUser(next.userData ?? ProfileData());
      }
    });
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: KeyboardDismisser(
        child: Container(
          margin: MediaQuery.of(context).viewInsets,
          decoration: BoxDecoration(
            // Shipped chrome was light-only bgGrey@96%; promoted, the
            // sheet resolves the dark surface in dark mode (frame 4d,
            // chip 725).
            color: (AppStyle.isDark ? AppStyle.surfaceDark : AppStyle.bgGrey)
                .withValues(alpha: 0.96),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
            ),
          ),
          width: double.infinity,
          child: state.isLoading
              ? const Loading()
              : Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: SingleChildScrollView(
                    controller: widget.controller,
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              8.verticalSpace,
                              Center(
                                child: Container(
                                  height: 4.h,
                                  width: 48.w,
                                  decoration: BoxDecoration(
                                    color: AppStyle.dragElement,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(40.r),
                                    ),
                                  ),
                                ),
                              ),
                              24.verticalSpace,
                              TitleAndIcon(
                                title: AppHelpers.getTranslation(
                                  TrKeys.profileSettings,
                                ),
                                paddingHorizontalSize: 0,
                                titleSize: 18,
                              ),
                              24.verticalSpace,
                              Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(42.r),
                                      color: AppStyle.shimmerBase,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(42.r),
                                      child:
                                          ((user?.img?.isNotEmpty ?? false) &&
                                                  state.imagePath.isEmpty)
                                              ? CustomNetworkImage(
                                                  profile: true,
                                                  url: user!.img ?? "",
                                                  height: 84.r,
                                                  width: 84.r,
                                                  radius: 42.r,
                                                )
                                              : state.imagePath.isNotEmpty
                                                  ? Image.file(
                                                      File(state.imagePath),
                                                      width: 84.r,
                                                      height: 84.r,
                                                    )
                                                  : CustomNetworkImage(
                                                      profile: true,
                                                      url: state.url,
                                                      height: 84.r,
                                                      width: 84.r,
                                                      radius: 42.r,
                                                    ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: 56.h,
                                      left: 50.w,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        event.getPhoto();
                                      },
                                      child: Container(
                                        width: 38.w,
                                        height: 38.h,
                                        decoration: BoxDecoration(
                                          color: AppStyle.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppStyle.borderColor,
                                          ),
                                        ),
                                        child: const Icon(
                                          Remix.pencil_line,
                                          color: AppStyle.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              24.verticalSpace,
                              OutlinedBorderTextField(
                                readOnly: AppValidators.isValidEmail(
                                  user?.email ?? '',
                                ),
                                label: AppHelpers.getTranslation(
                                  TrKeys.email,
                                ).toUpperCase(),
                                initialText: user?.email ?? "",
                                validation: AppValidators.emailCheck,
                                onChanged: event.setEmail,
                              ),
                              34.verticalSpace,
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: (MediaQuery.sizeOf(context).width -
                                            88) /
                                        2,
                                    child: OutlinedBorderTextField(
                                      label: AppHelpers.getTranslation(
                                        TrKeys.firstname,
                                      ).toUpperCase(),
                                      initialText: user?.firstname ?? "",
                                      validation:
                                          AppValidators.isNotEmptyValidator,
                                      onChanged: (s) {
                                        event.setFirstName(s);
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    width: (MediaQuery.sizeOf(context).width -
                                            40) /
                                        2,
                                    child: OutlinedBorderTextField(
                                      label: AppHelpers.getTranslation(
                                        TrKeys.surname,
                                      ).toUpperCase(),
                                      initialText: user?.lastname ?? "",
                                      validation:
                                          AppValidators.isNotEmptyValidator,
                                      onChanged: (s) {
                                        event.setLastName(s);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              34.verticalSpace,
                              OutlinedBorderTextField(
                                readOnly: true,
                                label: AppHelpers.getTranslation(
                                  TrKeys.phoneNumber,
                                ).toUpperCase(),
                                hint: "+1 990 000 00 00",
                                initialText: user?.phone ?? "",
                                validation: AppValidators.isNotEmptyValidator,
                                onTap: () {
                                  AppHelpers.showCustomModalBottomSheet(
                                    context: context,
                                    modal: EmbeddedWidgets.I.phoneVerify(),
                                    isDarkMode: false,
                                    paddingTop: MediaQuery.paddingOf(
                                      context,
                                    ).top,
                                  );
                                },
                              ),
                              34.verticalSpace,
                              OutlinedBorderTextField(
                                onTap: () {
                                  AppHelpers.showCustomModalBottomSheet(
                                    context: context,
                                    modal: Container(
                                      height: 250.h,
                                      padding: const EdgeInsets.only(top: 6.0),
                                      margin: EdgeInsets.only(
                                        bottom: MediaQuery.viewInsetsOf(
                                          context,
                                        ).bottom,
                                      ),
                                      color: CupertinoColors.systemBackground
                                          .resolveFrom(context),
                                      child: SafeArea(
                                        top: false,
                                        child: CupertinoDatePicker(
                                          initialDateTime: DateTime.tryParse(
                                                birthDay.text,
                                              )?.toLocal() ??
                                              DateTime.now(),
                                          maximumDate: DateTime.now(),
                                          mode: CupertinoDatePickerMode.date,
                                          use24hFormat: true,
                                          onDateTimeChanged:
                                              (DateTime newDate) {
                                            birthDay.text = intl.DateFormat(
                                              "yyyy-MM-dd",
                                            ).format(newDate);
                                            event.setBirth(
                                              newDate.toString(),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    isDarkMode: false,
                                  );
                                },
                                readOnly: true,
                                label: AppHelpers.getTranslation(
                                  TrKeys.dateOfBirth,
                                ).toUpperCase(),
                                hint: "YYYY-MM-DD",
                                validation: AppValidators.isNotEmptyValidator,
                                textController: birthDay,
                              ),
                              34.verticalSpace,
                              UnderlineDropDown(
                                value: user?.gender,
                                hint: AppHelpers.getTranslation(
                                  TrKeys.typeHere,
                                ),
                                label: AppHelpers.getTranslation(
                                  TrKeys.gender,
                                ).toUpperCase(),
                                list: AppConstants.genderList,
                                onChanged: event.setGender,
                                validator: (s) {
                                  if (s?.isNotEmpty ?? false) {
                                    return null;
                                  }
                                  return AppHelpers.getTranslation(
                                    TrKeys.canNotBeEmpty,
                                  );
                                },
                              ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  MediaQuery.of(context).padding.bottom + 24.h,
                              top: 24.h,
                            ),
                            child: CustomButton(
                              title: AppHelpers.getTranslation(TrKeys.save),
                              onPressed: () {
                                if (formKey.currentState?.validate() ?? false) {
                                  event.editProfile(context, user!);
                                }
                              },
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
