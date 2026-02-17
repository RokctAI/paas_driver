import 'dart:io';
import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:driver/application/profile/notifier/profile_edit_notifier.dart';
import 'package:driver/application/profile/notifier/profile_image_notifier.dart';
import 'package:driver/infrastructure/services/services.dart';
import 'package:driver/presentation/component/components.dart';
import 'package:driver/presentation/component/loading.dart';
import 'package:driver/presentation/pages/profile/widgets/logout_modal.dart';
import 'package:driver/presentation/styles/style.dart';

import '../../../../application/providers.dart';

@RoutePage()
class BecomeDriverPage extends ConsumerStatefulWidget {
  const BecomeDriverPage({super.key});

  @override
  ConsumerState<BecomeDriverPage> createState() => _EditRestaurantState();
}

class _EditRestaurantState extends ConsumerState<BecomeDriverPage> {
  late TextEditingController brand;
  late TextEditingController model;
  late TextEditingController number;
  late TextEditingController color;

  late TextEditingController height;
  late TextEditingController weight;
  late TextEditingController length;
  late TextEditingController width;
  String? dropdownValue;
  String? imagePath;
  late ProfileEditNotifier event;
  late ProfileImageNotifier eventImage;

  var items = [
    AppHelpers.getTranslation(TrKeys.benzine),
    AppHelpers.getTranslation(TrKeys.diesel),
    AppHelpers.getTranslation(TrKeys.gas),
    AppHelpers.getTranslation(TrKeys.motorbike),
    AppHelpers.getTranslation(TrKeys.bike),
    AppHelpers.getTranslation(TrKeys.foot),
  ];

  @override
  void initState() {
    brand = TextEditingController(
      text: LocalStorage.getDeliveryInfo()?.data?.brand ?? "",
    );
    model = TextEditingController(
      text: LocalStorage.getDeliveryInfo()?.data?.model ?? "",
    );
    number = TextEditingController(
      text: LocalStorage.getDeliveryInfo()?.data?.number ?? "",
    );
    color = TextEditingController(
      text: LocalStorage.getDeliveryInfo()?.data?.color ?? "",
    );

    height = TextEditingController(
      text: LocalStorage.getDeliveryInfo()?.data?.height ?? "",
    );
    weight = TextEditingController(
      text: LocalStorage.getDeliveryInfo()?.data?.kg ?? "",
    );
    length = TextEditingController(
      text: LocalStorage.getDeliveryInfo()?.data?.length ?? "",
    );
    width = TextEditingController(
      text: LocalStorage.getDeliveryInfo()?.data?.width ?? "",
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(profileImageProvider.notifier)
          .setUrlCar(
            LocalStorage.getDeliveryInfo()?.data?.galleries?.first.path,
          );

      ref
          .read(profileSettingsProvider.notifier)
          .fetchRequestResponse(context: context);
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    event = ref.read(profileEditProvider.notifier);
    eventImage = ref.read(profileImageProvider.notifier);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    brand.dispose();
    model.dispose();
    number.dispose();
    color.dispose();
    height.dispose();
    weight.dispose();
    length.dispose();
    width.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileEditProvider);
    final userState = ref.watch(profileSettingsProvider);
    final stateImage = ref.watch(profileImageProvider);
    return KeyboardDisable(
      child: Scaffold(
        body: Column(
          children: [
            CustomAppBar(
              bottomPadding: 16,
              child: Text(
                AppHelpers.getTranslation(TrKeys.becomeDriver),
                style: Style.interSemi(size: 18, color: Style.black),
              ),
            ),
            userState.isLoading
                ? const Expanded(child: Loading())
                : userState.requestData?.status == "pending"
                ? Expanded(
                    child: Column(
                      children: [
                        Lottie.asset('assets/lottie/processing.json'),
                        24.verticalSpace,
                        Text(
                          AppHelpers.getTranslation(TrKeys.yourRequest),
                          style: Style.interNormal(
                            size: 18,
                            color: Style.black,
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: REdgeInsets.all(24),
                          child: CustomButton(
                            title: AppHelpers.getTranslation(TrKeys.logout),
                            onPressed: () =>
                                AppHelpers.showCustomModalBottomSheet(
                                  context: context,
                                  modal: const LogoutModal(),
                                  isDarkMode: LocalStorage.getAppThemeMode(),
                                ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (userState.requestData?.status == "canceled")
                                  Column(
                                    children: [
                                      24.verticalSpace,
                                      Text(
                                        userState.requestData?.statusNote ?? '',
                                        style: Style.interNormal(
                                          size: 16,
                                          color: Style.black,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                24.verticalSpace,
                                DropdownButtonFormField(
                                  initialValue: dropdownValue,
                                  items: items.map((String item) {
                                    return DropdownMenuItem(
                                      value: item,
                                      child: Text(item),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    dropdownValue = newValue!;
                                    event.setPhone("");
                                  },
                                  decoration: InputDecoration(
                                    labelText: AppHelpers.getTranslation(
                                      TrKeys.typeTechnique,
                                    ).toUpperCase(),
                                    labelStyle: Style.interNormal(
                                      size: 14.sp,
                                      color: Style.black,
                                    ),
                                    contentPadding: REdgeInsets.symmetric(
                                      horizontal: 0,
                                      vertical: 8,
                                    ),
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.always,
                                    enabledBorder: const UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Style.shimmerBase,
                                      ),
                                    ),
                                    errorBorder: InputBorder.none,
                                    border: const UnderlineInputBorder(),
                                    focusedErrorBorder:
                                        const UnderlineInputBorder(),
                                    disabledBorder: const UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Style.shimmerBase,
                                      ),
                                    ),
                                    focusedBorder: const UnderlineInputBorder(),
                                  ),
                                ),
                                24.verticalSpace,
                                UnderlinedBorderTextField(
                                  label: AppHelpers.getTranslation(
                                    TrKeys.carBrand,
                                  ),
                                  textController: brand,
                                  onChanged: (s) {
                                    event.setPhone("");
                                  },
                                ),
                                24.verticalSpace,
                                UnderlinedBorderTextField(
                                  label: AppHelpers.getTranslation(
                                    TrKeys.carModels,
                                  ),
                                  textController: model,
                                  onChanged: (s) {
                                    event.setPhone("");
                                  },
                                ),
                                24.verticalSpace,
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: UnderlinedBorderTextField(
                                        label: AppHelpers.getTranslation(
                                          TrKeys.stateNumber,
                                        ),
                                        textController: number,
                                        onChanged: (s) {
                                          event.setPhone("");
                                        },
                                      ),
                                    ),
                                    10.horizontalSpace,
                                    Expanded(
                                      flex: 1,
                                      child: UnderlinedBorderTextField(
                                        label: AppHelpers.getTranslation(
                                          TrKeys.color,
                                        ),
                                        textController: color,
                                        onChanged: (s) {
                                          event.setPhone("");
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                24.verticalSpace,
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: UnderlinedBorderTextField(
                                        label: AppHelpers.getTranslation(
                                          TrKeys.height,
                                        ),
                                        textController: height,
                                        inputType: TextInputType.number,
                                        onChanged: (s) {
                                          event.setPhone("");
                                        },
                                      ),
                                    ),
                                    10.horizontalSpace,
                                    Expanded(
                                      flex: 1,
                                      child: UnderlinedBorderTextField(
                                        label: AppHelpers.getTranslation(
                                          TrKeys.weight,
                                        ),
                                        textController: weight,
                                        inputType: TextInputType.number,
                                        onChanged: (s) {
                                          event.setPhone("");
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                24.verticalSpace,
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: UnderlinedBorderTextField(
                                        label: AppHelpers.getTranslation(
                                          TrKeys.length,
                                        ),
                                        textController: length,
                                        inputType: TextInputType.number,
                                      ),
                                    ),
                                    10.horizontalSpace,
                                    Expanded(
                                      flex: 1,
                                      child: UnderlinedBorderTextField(
                                        label: AppHelpers.getTranslation(
                                          TrKeys.width,
                                        ),
                                        textController: width,
                                        inputType: TextInputType.number,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          16.verticalSpace,
                          InkWell(
                            onTap: () async {
                              final XFile? pickedFile = await ImagePicker()
                                  .pickImage(source: ImageSource.gallery);
                              imagePath = pickedFile?.path;
                              eventImage.setUrlCar(null);
                              if (imagePath != null) {
                                eventImage.editCarImage(
                                  // ignore: use_build_context_synchronously
                                  context: context,
                                  path: imagePath!,
                                );
                              }
                            },
                            child: Container(
                              height: 160.h,
                              width: double.infinity,
                              margin: EdgeInsets.all(16.r),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(color: Style.hintColor),
                              ),
                              child: stateImage.carImageUrl == null
                                  ? imagePath == null
                                        ? Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                FlutterRemix
                                                    .upload_cloud_2_line,
                                                size: 36.sp,
                                                color: Style.primary,
                                              ),
                                              16.verticalSpace,
                                              Text(
                                                AppHelpers.getTranslation(
                                                  TrKeys.carPicture,
                                                ),
                                                style: Style.interSemi(
                                                  size: 14.sp,
                                                ),
                                              ),
                                              Text(
                                                AppHelpers.getTranslation(
                                                  TrKeys.recommendedSize,
                                                ),
                                                style: Style.interRegular(
                                                  size: 14.sp,
                                                ),
                                              ),
                                            ],
                                          )
                                        : ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              20.r,
                                            ),
                                            child: Image.file(
                                              File(imagePath!),
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                  : CommonImage(
                                      imageUrl: stateImage.carImageUrl,
                                      height: 160,
                                      radius: 20,
                                    ),
                            ),
                          ),
                          8.verticalSpace,
                          Builder(
                            builder: (context) {
                              return Padding(
                                padding: EdgeInsets.all(16.r),
                                child: CustomButton(
                                  textColor:
                                      (dropdownValue?.isNotEmpty ?? false) &&
                                          brand.text.isNotEmpty &&
                                          model.text.isNotEmpty &&
                                          number.text.isNotEmpty &&
                                          color.text.isNotEmpty &&
                                          height.text.isNotEmpty &&
                                          weight.text.isNotEmpty &&
                                          width.text.isNotEmpty &&
                                          length.text.isNotEmpty
                                      ? Style.black
                                      : Style.white,
                                  background:
                                      (dropdownValue?.isNotEmpty ?? false) &&
                                          brand.text.isNotEmpty &&
                                          model.text.isNotEmpty &&
                                          number.text.isNotEmpty &&
                                          color.text.isNotEmpty &&
                                          height.text.isNotEmpty &&
                                          weight.text.isNotEmpty &&
                                          width.text.isNotEmpty &&
                                          length.text.isNotEmpty
                                      ? Style.primary
                                      : Style.shadowColor,
                                  isLoading: state.isLoading,
                                  title: AppHelpers.getTranslation(TrKeys.save),
                                  onPressed: () {
                                    if ((dropdownValue?.isNotEmpty ?? false) &&
                                        brand.text.isNotEmpty &&
                                        model.text.isNotEmpty &&
                                        number.text.isNotEmpty &&
                                        color.text.isNotEmpty &&
                                        height.text.isNotEmpty &&
                                        weight.text.isNotEmpty &&
                                        width.text.isNotEmpty &&
                                        length.text.isNotEmpty) {
                                      event.createCarInfo(
                                        context: context,
                                        type: AppHelpers.getTranslationReverse(
                                          dropdownValue!,
                                        ),
                                        brand: brand.text,
                                        model: model.text,
                                        number: number.text,
                                        color: color.text,
                                        imageUrl: stateImage.carImageUrl,
                                        updated: () {
                                          ref
                                              .read(
                                                profileSettingsProvider
                                                    .notifier,
                                              )
                                              .fetchRequestResponse(
                                                context: context,
                                              );
                                        },
                                        height: height.text,
                                        weight: weight.text,
                                        length: length.text,
                                        width: width.text,
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
