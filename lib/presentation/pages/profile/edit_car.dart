import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:driver/application/profile/notifier/profile_edit_notifier.dart';
import 'package:driver/application/profile/notifier/profile_image_notifier.dart';
import 'package:driver/application/profile/provider/profile_edit_provider.dart';
import 'package:driver/application/profile/provider/profile_image_provider.dart';
import 'package:driver/application/profile/state/profile_edit_state.dart';
import 'package:driver/application/profile/state/profile_image_state.dart';
import 'package:driver/infrastructure/services/img_service.dart';

import 'package:driver/infrastructure/services/services.dart';
import 'package:driver/presentation/component/components.dart';
import 'package:driver/presentation/styles/style.dart';

class EditCar extends ConsumerStatefulWidget {
  const EditCar({super.key});

  @override
  ConsumerState<EditCar> createState() => _EditCarState();
}

class _EditCarState extends ConsumerState<EditCar> {
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
  late ProfileEditState state;
  late ProfileImageState stateImage;

  var items = [
    TrKeys.benzine,
    TrKeys.diesel,
    TrKeys.gas,
    TrKeys.motorbike,
    TrKeys.bike,
    TrKeys.foot,
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
    dropdownValue = LocalStorage.getDeliveryInfo()?.data?.typeOfTechnique;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(profileImageProvider.notifier)
          .setUrlCar(
            LocalStorage.getDeliveryInfo()?.data?.galleries?.first.path,
          );
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
    state = ref.watch(profileEditProvider);
    stateImage = ref.watch(profileImageProvider);
    return KeyboardDisable(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                TitleAndIcon(
                  title: AppHelpers.getTranslation(TrKeys.carSettings),
                ),
                24.verticalSpace,
                IgnorePointer(
                  ignoring: AppHelpers.getDriverCantEdit(),
                  child: DropdownButtonFormField(
                    initialValue: dropdownValue,
                    items: items.map((String item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text(AppHelpers.getTranslation(item)),
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
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Style.shimmerBase),
                      ),
                      errorBorder: InputBorder.none,
                      border: const UnderlineInputBorder(),
                      focusedErrorBorder: const UnderlineInputBorder(),
                      disabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Style.shimmerBase),
                      ),
                      focusedBorder: const UnderlineInputBorder(),
                    ),
                  ),
                ),
                24.verticalSpace,
                UnderlinedBorderTextField(
                  readOnly: AppHelpers.getDriverCantEdit(),
                  label: AppHelpers.getTranslation(TrKeys.carBrand),
                  textController: brand,
                  onChanged: (s) {
                    event.setPhone("");
                  },
                ),
                24.verticalSpace,
                UnderlinedBorderTextField(
                  readOnly: AppHelpers.getDriverCantEdit(),
                  label: AppHelpers.getTranslation(TrKeys.carModels),
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
                        readOnly: AppHelpers.getDriverCantEdit(),
                        label: AppHelpers.getTranslation(TrKeys.stateNumber),
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
                        readOnly: AppHelpers.getDriverCantEdit(),
                        label: AppHelpers.getTranslation(TrKeys.color),
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
                        readOnly: AppHelpers.getDriverCantEdit(),
                        label: AppHelpers.getTranslation(TrKeys.height),
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
                        readOnly: AppHelpers.getDriverCantEdit(),
                        label: AppHelpers.getTranslation(TrKeys.weight),
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
                        readOnly: AppHelpers.getDriverCantEdit(),
                        label: AppHelpers.getTranslation(TrKeys.length),
                        textController: length,
                        inputType: TextInputType.number,
                      ),
                    ),
                    10.horizontalSpace,
                    Expanded(
                      flex: 1,
                      child: UnderlinedBorderTextField(
                        readOnly: AppHelpers.getDriverCantEdit(),
                        label: AppHelpers.getTranslation(TrKeys.width),
                        textController: width,
                        inputType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          24.verticalSpace,
          InkWell(
            onTap: () async {
              if (AppHelpers.getDriverCantEdit()) return;
              ImgService.getPhotoGallery((s) {
                imagePath = s;
                eventImage.setUrlCar(null);
                eventImage.editCarImage(context: context, path: imagePath!);
              });
            },
            child: Container(
              height: 160.h,
              margin: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: Style.black),
              ),
              child: stateImage.carImageUrl == null
                  ? imagePath == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                FlutterRemix.upload_cloud_2_line,
                                size: 36.sp,
                                color: Style.blueColor,
                              ),
                              16.verticalSpace,
                              Text(
                                AppHelpers.getTranslation(TrKeys.carPicture),
                                style: Style.interSemi(size: 14.sp),
                              ),
                              Text(
                                AppHelpers.getTranslation(
                                  TrKeys.recommendedSize,
                                ),
                                style: Style.interRegular(size: 14.sp),
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(20.r),
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
          24.verticalSpace,
          Padding(
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
                  event.editCarInfo(
                    context: context,
                    type: AppHelpers.getTranslationReverse(dropdownValue!),
                    brand: brand.text,
                    model: model.text,
                    number: number.text,
                    color: color.text,
                    imageUrl: stateImage.carImageUrl,
                    updated: () {
                      context.router.maybePop();
                    },
                    height: height.text,
                    weight: weight.text,
                    length: length.text,
                    width: width.text,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
