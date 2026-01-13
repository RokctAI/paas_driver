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

import '../../../application/vehicles/vehicle_providers.dart';
import '../../../infrastructure/models/data/delivery_vehicle_type.dart';

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

  String dropdownValue = ""; // Initialize with empty string instead of null
  String? imagePath;
  late ProfileEditNotifier event;
  late ProfileImageNotifier eventImage;
  late ProfileEditState state;
  late ProfileImageState stateImage;
  bool _isInitialized = false;
  List<DeliveryVehicleType> vehicleTypes = [];

  @override
  void initState() {
    super.initState();

    brand = TextEditingController(
        text: LocalStorage.getDeliveryInfo()?.data?.brand ?? "");
    model = TextEditingController(
        text: LocalStorage.getDeliveryInfo()?.data?.model ?? "");
    number = TextEditingController(
        text: LocalStorage.getDeliveryInfo()?.data?.number ?? "");
    color = TextEditingController(
        text: LocalStorage.getDeliveryInfo()?.data?.color ?? "");

    height = TextEditingController(
        text: LocalStorage.getDeliveryInfo()?.data?.height ?? "");
    weight = TextEditingController(
        text: LocalStorage.getDeliveryInfo()?.data?.kg ?? "");
    length = TextEditingController(
        text: LocalStorage.getDeliveryInfo()?.data?.length ?? "");
    width = TextEditingController(
        text: LocalStorage.getDeliveryInfo()?.data?.width ?? "");

    // Set initial dropdown value from storage or empty string
    final storedValue = LocalStorage.getDeliveryInfo()?.data?.typeOfTechnique;
    dropdownValue = storedValue ?? "";

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileImageProvider.notifier).setUrlCar(
          LocalStorage.getDeliveryInfo()?.data?.galleries?.first.path);
    });
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

  // Helper method to get selected vehicle type
  DeliveryVehicleType? get selectedVehicleType {
    if (dropdownValue.isEmpty || vehicleTypes.isEmpty) return null;
    try {
      return vehicleTypes.firstWhere((type) => type.key == dropdownValue);
    } catch (e) {
      return null;
    }
  }

  // Helper method to update weight based on selected vehicle type
  void updateWeightFromVehicleType() {
    final selectedType = selectedVehicleType;
    if (selectedType != null && selectedType.weightCapacity > 0) {
      weight.text = selectedType.weightCapacity.toString();
    }
  }

  // Helper method to check if all fields are valid
  bool get isFormValid {
    // Only check required fields: brand, model, number, color, dropdown
    // Height, weight, width, length are optional
    return brand.text.trim().isNotEmpty &&
        model.text.trim().isNotEmpty &&
        number.text.trim().isNotEmpty &&
        color.text.trim().isNotEmpty &&
        dropdownValue.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    state = ref.watch(profileEditProvider);
    stateImage = ref.watch(profileImageProvider);
    final vehicleTypeState = ref.watch(vehicleTypeProvider);

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
                vehicleTypeState.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (msg) => Text('Error: $msg', style: const TextStyle(color: Colors.red)),
                  data: (types) {
                    vehicleTypes = types; // Store the types for later use
                    final keys = types.map((e) => e.key).toList();

                    // Initialize dropdown value once when API data is available
                    if (!_isInitialized && keys.isNotEmpty) {
                      if (dropdownValue.isEmpty || !keys.contains(dropdownValue)) {
                        dropdownValue = keys.first;
                        // Auto-update weight when dropdown is initialized
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          updateWeightFromVehicleType();
                        });
                      }
                      _isInitialized = true;
                      // Trigger rebuild to reflect the initial state
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() {});
                      });
                    }

                    // Ensure dropdownValue is valid
                    if (dropdownValue.isEmpty || !keys.contains(dropdownValue)) {
                      dropdownValue = keys.isNotEmpty ? keys.first : "";
                    }

                    return DropdownButtonFormField<String>(
                      value: dropdownValue.isEmpty ? null : dropdownValue,
                      items: types.map((vehicleType) => DropdownMenuItem(
                        value: vehicleType.key,
                        child: Text(
                          vehicleType.name,
                          style: Style.interNormal(size: 14.sp),
                        ),
                      )).toList(),
                      onChanged: AppHelpers.getDriverCantEdit()
                          ? null
                          : (value) {
                        setState(() {
                          dropdownValue = value ?? "";
                          // Auto-update weight when vehicle type changes
                          updateWeightFromVehicleType();
                        });
                      },
                      autovalidateMode: AutovalidateMode.disabled,
                      validator: null, // Remove any validation
                      decoration: InputDecoration(
                        labelText: AppHelpers.getTranslation(TrKeys.typeTechnique).toUpperCase(),
                        labelStyle: Style.interNormal(size: 14.sp, color: Style.black),
                        contentPadding: REdgeInsets.symmetric(horizontal: 0, vertical: 8),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Style.shimmerBase)),
                        border: const UnderlineInputBorder(),
                        focusedBorder: const UnderlineInputBorder(),
                        errorBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Style.shimmerBase)), // Same as enabled
                        focusedErrorBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Style.shimmerBase)), // Same as enabled
                        disabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Style.shimmerBase)),
                        errorStyle: const TextStyle(height: 0), // Hide error text
                      ),
                    );
                  },
                ),
                24.verticalSpace,
                UnderlinedBorderTextField(
                  readOnly: AppHelpers.getDriverCantEdit(),
                  label: AppHelpers.getTranslation(TrKeys.carBrand),
                  textController: brand,
                  onChanged: (_) {
                    setState(() {}); // Just trigger rebuild for button state
                  },
                ),
                24.verticalSpace,
                UnderlinedBorderTextField(
                  readOnly: AppHelpers.getDriverCantEdit(),
                  label: AppHelpers.getTranslation(TrKeys.carModels),
                  textController: model,
                  onChanged: (_) {
                    setState(() {}); // Just trigger rebuild for button state
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
                        onChanged: (_) {
                          setState(() {}); // Just trigger rebuild for button state
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
                        onChanged: (_) {
                          setState(() {}); // Just trigger rebuild for button state
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
                        onChanged: (_) {
                          setState(() {}); // Just trigger rebuild for button state
                        },
                      ),
                    ),
                    10.horizontalSpace,
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UnderlinedBorderTextField(
                            readOnly: true, // Make weight field read-only
                            label: AppHelpers.getTranslation(TrKeys.weight),
                            textController: weight,
                            inputType: TextInputType.number,
                            onChanged: (_) {
                              setState(() {}); // Just trigger rebuild for button state
                            },
                          ),
                          if (selectedVehicleType != null) ...[
                            4.verticalSpace,
                            Text(
                              'Max: ${selectedVehicleType!.weightCapacity}kg',
                              style: Style.interRegular(
                                  size: 12.sp,
                                  color: Style.textColor.withOpacity(0.6)
                              ),
                            ),
                          ],
                        ],
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
                        onChanged: (_) {
                          setState(() {}); // Trigger rebuild
                        },
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
                        onChanged: (_) {
                          setState(() {}); // Trigger rebuild
                        },
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
                  border: Border.all(color: Style.black)),
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
                          TrKeys.recommendedSize),
                      style: Style.interRegular(size: 14.sp)),
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
              textColor: isFormValid ? Style.black : Style.white,
              background: isFormValid ? Style.primaryColor : Style.shadowColor,
              isLoading: state.isLoading,
              title: AppHelpers.getTranslation(TrKeys.save),
              onPressed: isFormValid ? () {
                event.editCarInfo(
                  context: context,
                  type: dropdownValue, // Use the key directly instead of reverse translation
                  brand: brand.text,
                  model: model.text,
                  number: number.text,
                  color: color.text,
                  imageUrl: stateImage.carImageUrl,
                  updated: () {
                    context.router.maybePop();
                  },
                  height: height.text,
                  weight: weight.text, // This will now contain the vehicle type's max weight
                  length: length.text,
                  width: width.text,
                );
              } : null,
            ),
          ),
        ],
      ),
    );
  }
}