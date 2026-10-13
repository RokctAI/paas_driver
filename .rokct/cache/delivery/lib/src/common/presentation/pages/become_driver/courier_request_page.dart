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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:base_sdk/src/domain/interface/gallery.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

import 'package:delivery_sdk/src/common/presentation/widgets/vehicle_details_slide.dart';

/// "Sign up to deliver" in the customer app ("Becoming a seller or
/// driver"): an existing customer applies to drive with the same
/// vehicle-details form the driver app's sign-up uses, sending the same
/// courier request. An admin approves it, which makes the account a driver;
/// the driver app then lets them in.
///
/// Declared to the host as `EmbeddedWidgets.becomeDriverPage` (this SDK's
/// manifest), which the customer profile's tile opens. It used to point at
/// nothing, so the tile threw.
class CourierRequestPage extends StatefulWidget {
  const CourierRequestPage({super.key});

  @override
  State<CourierRequestPage> createState() => _CourierRequestPageState();
}

class _CourierRequestPageState extends State<CourierRequestPage> {
  final CourierRequestCapture _capture = CourierRequestCapture();

  void _done() {
    final String? error = _capture.error;
    AppHelpers.showCheckTopSnackBar(
      context,
      error ?? CourierRequestCapture.sentMessage,
    );
    if (error == null) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.surfaceFor(Theme.of(context).brightness),
      appBar: AppBar(
        title: Text(AppHelpers.getTranslation(TrKeys.signUpToDeliver)),
      ),
      body: SafeArea(
        child: VehicleDetailsSlide(capture: _capture, onContinue: _done),
      ),
    );
  }
}

/// Files the courier request as the signed-in account: the vehicle details
/// ride in a Request Model (`api.user.create_request_model`, kind
/// `deliveryman`) for an admin to approve, the same payload as the driver
/// app's sign-up step. Unlike that step it remembers the outcome, so the
/// page can tell the customer whether the request went through.
class CourierRequestCapture implements CourierVehicleCapture {
  /// Shown when the request was sent.
  static const String sentMessage =
      'Request sent. You can use the driver app once it is approved';

  /// Why the last submit failed, or null when it went through.
  String? error;

  @override
  Future<void> submitVehicle({
    required String type,
    required String brand,
    required String model,
    required String number,
    required String color,
    required String height,
    required String width,
    required String length,
    required String weight,
    String? imagePath,
  }) async {
    error = null;
    String? imageUrl;
    final getIt = GetIt.instance;
    if (imagePath != null &&
        imagePath.isNotEmpty &&
        getIt.isRegistered<GalleryRepositoryFacade>()) {
      final upload = await getIt
          .get<GalleryRepositoryFacade>()
          .uploadImage(imagePath, UploadType.users);
      // A failed photo upload still sends the request without the photo.
      upload.when(
        success: (data) => imageUrl = data.imageData?.title,
        failure: (failure, statusCode) =>
            debugPrint('==> courier request photo upload failed: $failure'),
      );
    }
    try {
      await const PlatformGateway().tenant('api.user.create_request_model', {
        'model_type': 'deliveryman',
        'model_id': LocalStorage.getUser()?.id ?? '',
        'data': jsonEncode({
          'type_of_technique': type,
          'brand': brand,
          'model': model,
          'number': number,
          'color': color,
          'height': int.tryParse(height) ?? 0,
          'width': int.tryParse(width) ?? 0,
          'kg': int.tryParse(weight) ?? 0,
          'length': int.tryParse(length) ?? 0,
          if (imageUrl != null) 'images': [imageUrl],
        }),
      });
    } catch (e) {
      error = AppHelpers.errorHandler(e);
    }
  }
}
