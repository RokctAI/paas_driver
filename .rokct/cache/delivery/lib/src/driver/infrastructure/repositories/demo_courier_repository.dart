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

import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/models/response/driver_show_response.dart';
import 'package:base_sdk/src/models/response/profile_response.dart';

import 'package:delivery_sdk/src/driver/domain/interface/courier.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/delivery_vehicle_type.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/response/request_model_response.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/demo_delivery_seed.dart';

/// Demo-only [CourierRepositoryFacade] (`--dart-define=IS_DEMO=true`):
/// serves the fictional [DemoDeliverySeed] courier profile, vehicle types,
/// settings and delivery zone offline. Registered in place of
/// [CourierRepository] by DriverDeliveryDependencies when demo mode is on.
/// Never used in production; every write is acknowledged locally and
/// nothing leaves the device.
class DemoCourierRepository implements CourierRepositoryFacade {
  @override
  Future<ApiResult<DeliveryResponse>> getDriverDetails() async {
    return ApiResult.success(
      data: DeliveryResponse.fromJson(DemoDeliverySeed.driverDetails()),
    );
  }

  @override
  Future<ApiResult<Map<String, dynamic>>> getDeliverymanSettingsRaw() async {
    return ApiResult.success(data: DemoDeliverySeed.deliverymanSettings());
  }

  @override
  Future<ApiResult<List<DeliveryVehicleType>>> getDeliveryVehicleTypes() async {
    return ApiResult.success(
      data: DemoDeliverySeed.vehicleTypes()
          .map(DeliveryVehicleType.fromJson)
          .toList(),
    );
  }

  @override
  Future<ApiResult<ProfileResponse>> updateGeneralInfo({
    required String firstName,
    String? lastName,
    String? phone,
    String? email,
    String? password,
    String? confirmPassword,
  }) async {
    final profile = DemoDeliverySeed.profileData();
    profile['firstname'] = firstName;
    if (lastName != null) profile['lastname'] = lastName;
    if (phone != null) profile['phone'] = phone;
    if (email != null) profile['email'] = email;
    return ApiResult.success(
      data: ProfileResponse.fromJson({'data': profile}),
    );
  }

  @override
  Future<ApiResult<DeliveryResponse>> editCarInfo({
    required String type,
    required String brand,
    required String model,
    required String number,
    required String color,
    required String height,
    required String weight,
    required String length,
    required String width,
    String? imageUrl,
  }) async {
    return _carInfo(
        type: type,
        brand: brand,
        model: model,
        number: number,
        color: color,
        height: height,
        weight: weight,
        length: length,
        width: width);
  }

  @override
  Future<ApiResult<DeliveryResponse>> createCarInfo({
    required String type,
    required String brand,
    required String model,
    required String number,
    required String color,
    required String height,
    required String weight,
    required String length,
    required String width,
    String? imageUrl,
  }) async {
    return _carInfo(
        type: type,
        brand: brand,
        model: model,
        number: number,
        color: color,
        height: height,
        weight: weight,
        length: length,
        width: width);
  }

  Future<ApiResult<DeliveryResponse>> _carInfo({
    required String type,
    required String brand,
    required String model,
    required String number,
    required String color,
    required String height,
    required String weight,
    required String length,
    required String width,
  }) async {
    final details = DemoDeliverySeed.driverDetails();
    final data = details['data'] as Map<String, dynamic>;
    data['type_of_technique'] = type;
    data['brand'] = brand;
    data['model'] = model;
    data['number'] = number;
    data['color'] = color;
    data['height'] = height;
    data['kg'] = weight;
    data['length'] = length;
    data['width'] = width;
    return ApiResult.success(data: DeliveryResponse.fromJson(details));
  }

  @override
  Future<ApiResult<RequestModelResponse>> getRequestModel() async {
    // No pending vehicle-change request in demo.
    return ApiResult.success(
      data: RequestModelResponse.fromJson(const {'data': [], 'meta': null}),
    );
  }

  @override
  Future<ApiResult<dynamic>> setOnline() async {
    return const ApiResult.success(data: true);
  }

  @override
  Future<ApiResult<dynamic>> setCurrentLocation(LatLng location) async {
    // Local-only acknowledgement — demo never reports a position anywhere.
    return const ApiResult.success(data: true);
  }

  @override
  Future<ApiResult<List<List<double>>>> getDeliveryZone() async {
    return ApiResult.success(data: DemoDeliverySeed.deliveryZone());
  }
}
