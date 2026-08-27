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

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import 'package:base_sdk/src/models/response/global_settings_response.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/img_service.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

/// Courier-only helpers carried out of paas_driver's host `AppHelpers` —
/// base_sdk's AppHelpers has no counterparts (they read deliveryman platform
/// settings or are courier-flow UI).
abstract class CourierHelpers {
  CourierHelpers._();

  /// Seconds a courier gets to accept a pushed order
  /// (`deliveryman_order_acceptance_time` platform setting).
  static int getAppDeliveryTime() {
    final List<SettingsData> settings = LocalStorage.getSettingsList();
    for (final setting in settings) {
      if (setting.key == 'deliveryman_order_acceptance_time') {
        return int.parse(setting.value ?? '30');
      }
    }
    return int.parse('30');
  }

  /// Whether the operator locked courier credential editing
  /// (`driver_can_edit_credentials` == "0").
  static bool getDriverCantEdit() {
    final List<SettingsData> settings = LocalStorage.getSettingsList();
    for (final setting in settings) {
      if (setting.key == 'driver_can_edit_credentials') {
        return setting.value == "0";
      }
    }
    return false;
  }

  /// Rasterises an asset for use as a map marker (home-page shop/user pins).
  static Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  /// Camera capture — base's ImgService only offers the gallery variants, so
  /// the host helper's camera path lives here.
  static Future<void> _getPhotoCamera(ValueChanged<String> onChange) async {
    XFile? file;
    try {
      file = await ImagePicker().pickImage(source: ImageSource.camera);
    } catch (ex) {
      debugPrint('===> trying to select image $ex');
    }
    if (file != null) {
      onChange.call(file.path);
    }
  }

  /// Camera / gallery / skip chooser used by the vehicle (car photo) flows.
  static openDialogImagePicker({
    required BuildContext context,
    required ValueChanged<String> onSuccess,
  }) {
    return showDialog(
      context: context,
      builder: (_) {
        return Builder(
          builder: (colors) {
            return Dialog(
              backgroundColor: AppStyle.transparent,
              insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                margin: EdgeInsets.all(24.w),
                width: double.infinity,
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: AppStyle.white,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      AppHelpers.getTranslation(TrKeys.selectPhoto),
                      textAlign: TextAlign.center,
                      style: AppStyle.interNormal(size: 18),
                    ),
                    const Divider(),
                    8.verticalSpace,
                    _PickerBouncingEffect(
                      child: GestureDetector(
                        onTap: () => _getPhotoCamera(onSuccess),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.r, vertical: 8.r),
                          child: Row(
                            children: [
                              const Icon(FlutterRemix.camera_lens_line),
                              4.horizontalSpace,
                              Text(
                                AppHelpers.getTranslation(TrKeys.takePhoto),
                                textAlign: TextAlign.center,
                                style: AppStyle.interNormal(size: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    8.verticalSpace,
                    _PickerBouncingEffect(
                      child: GestureDetector(
                        onTap: () => ImgService.getPhotoGallery(onSuccess),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.r, vertical: 8.r),
                          child: Row(
                            children: [
                              const Icon(FlutterRemix.gallery_line),
                              4.horizontalSpace,
                              Text(
                                AppHelpers.getTranslation(
                                    TrKeys.chooseFromLibrary),
                                textAlign: TextAlign.center,
                                style: AppStyle.interNormal(size: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    12.verticalSpace,
                    CustomButton(
                      background: AppStyle.shimmerBase,
                      title: AppHelpers.getTranslation(TrKeys.skip),
                      onPressed: () {
                        onSuccess.call('');
                      },
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Private copy of the host's tiny `ButtonsBouncingEffect` press animation —
/// SDK src cannot import the host-installed component copy this SDK ships
/// for its templates, and base_sdk has no equivalent.
class _PickerBouncingEffect extends StatefulWidget {
  final Widget child;

  const _PickerBouncingEffect({required this.child});

  @override
  State createState() => _PickerBouncingEffectState();
}

class _PickerBouncingEffectState extends State<_PickerBouncingEffect>
    with TickerProviderStateMixin {
  AnimationController? _controllerA;

  var squareScaleA = 0.95;

  @override
  void initState() {
    _controllerA = AnimationController(
      vsync: this,
      lowerBound: 0.95,
      upperBound: 1.0,
      duration: const Duration(milliseconds: 80),
    );
    _controllerA?.addListener(
      () {
        setState(() {
          squareScaleA = _controllerA!.value;
        });
      },
    );
    _controllerA?.forward(from: 0.0);
    super.initState();
  }

  @override
  void dispose() {
    _controllerA?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        _controllerA!.reverse();
      },
      onPointerUp: (_) {
        _controllerA!.forward(from: 1.0);
      },
      child: Transform.scale(
        scale: squareScaleA,
        child: widget.child,
      ),
    );
  }
}
