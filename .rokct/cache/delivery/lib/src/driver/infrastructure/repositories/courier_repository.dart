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

// compliance-ignore-file: flutter-http-timeout
// The package:dio import below is only for its request/response types.
// The actual client comes from base_sdk's dioHttp (HttpService), which sets
// connectTimeout and receiveTimeout (30s) centrally on its BaseOptions; no
// unconfigured HTTP client is created in this file.

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/models/response/driver_show_response.dart';
import 'package:base_sdk/src/models/response/profile_response.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';

import 'package:delivery_sdk/src/driver/di/driver_delivery_di.dart';
import 'package:delivery_sdk/src/driver/domain/interface/courier.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/delivery_vehicle_type.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/response/request_model_response.dart';
import 'package:delivery_sdk/src/driver/infrastructure/services/courier_storage.dart';

/// The deliveryman slice of paas_driver's legacy `UserRepositoryImpl`
/// (originally moved AS-IS, decision D2), now repointed off the dead
/// Laravel `/api/v1/dashboard/*` paths onto the whitelisted Frappe defs
/// through the universal platform gateway. Endpoint inventory recorded in
/// paas_driver's docs/fork-endpoint-handoff.md.
class CourierRepository implements CourierRepositoryFacade {
  static const _gateway = PlatformGateway();

  /// Prefix-free cmd bases for the universal platform gateway: the
  /// whitelisted-method keys from delivery's and Users' `manifest.json`
  /// (`{app_name}.api.delivery_man.*` / `{app_name}.api.user.*`) with
  /// the app segment dropped.
  static const _deliveryCmd = 'api.delivery_man';
  static const _userCmd = 'api.user';

  /// Builds the legacy [DeliveryResponse] the driver templates still
  /// consume from a Deliveryman Profile settings map (the bare
  /// `get_deliveryman_settings` / `update_deliveryman_settings` shape;
  /// that raw shape keeps its own consumer via
  /// [getDeliverymanSettingsRaw], so the mapping lives client-side
  /// instead of reshaping the def). Doctype keys map onto the Laravel
  /// vehicle model: car_model -> model, car_number -> number,
  /// latitude/longitude -> location, vehicle_image -> galleries[0];
  /// id/user_id/price/price_per_km/deliveryMan have no server home and
  /// stay null (render-optional in the templates).
  static DeliveryResponse _deliveryResponseFromSettings(dynamic body) {
    final settings =
        body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{};
    final online = settings['online'];
    final latitude = settings['latitude'];
    final longitude = settings['longitude'];
    final vehicleImage = settings['vehicle_image'];
    return DeliveryResponse(
      status: true,
      data: Data(
        typeOfTechnique: settings['type_of_technique']?.toString(),
        brand: settings['brand']?.toString(),
        model: settings['car_model']?.toString(),
        number: settings['car_number']?.toString(),
        color: settings['color']?.toString(),
        width: settings['width']?.toString(),
        height: settings['height']?.toString(),
        kg: settings['kg']?.toString(),
        length: settings['length']?.toString(),
        online: online is bool ? online : online == 1,
        location: (latitude == null && longitude == null)
            ? null
            : Location(
                latitude: latitude?.toString(),
                longitude: longitude?.toString(),
              ),
        galleries: vehicleImage == null
            ? null
            : [Galleries(path: vehicleImage.toString())],
      ),
    );
  }

  @override
  Future<ApiResult<DeliveryResponse>> getDriverDetails() async {
    try {
      // Repointed from the dead legacy
      // `/api/v1/dashboard/deliveryman/settings` path to the same
      // whitelisted Frappe def getDeliverymanSettingsRaw already calls,
      // through the universal platform gateway; the raw settings map is
      // folded into the legacy DeliveryResponse client-side.
      final response =
          await _gateway.tenant('$_deliveryCmd.get_deliveryman_settings');
      return ApiResult.success(
        data: _deliveryResponseFromSettings(response),
      );
    } catch (e) {
      debugPrint('===> error driver settings $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<Map<String, dynamic>>> getDeliverymanSettingsRaw() async {
    try {
      // Frappe convention endpoint (not the dead legacy `/api/v1` path),
      // called through the universal platform gateway — the prefix-free
      // cmd mirrors delivery's `manifest.json` whitelisted-method key.
      // FrappeResponseInterceptor already unwraps the top-level `message`
      // key, so the gateway answer is the settings map itself.
      final data =
          await _gateway.tenant('api.delivery_man.get_deliveryman_settings');
      return ApiResult.success(
        data: data is Map ? Map<String, dynamic>.from(data) : {},
      );
    } catch (e) {
      debugPrint('===> error deliveryman settings raw $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<List<DeliveryVehicleType>>> getDeliveryVehicleTypes() async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get('/api/v1/rest/delivery-vehicle-types');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data'];
        final items =
            data.map((item) => DeliveryVehicleType.fromJson(item)).toList();
        return ApiResult.success(data: items);
      } else {
        return ApiResult.failure(
          error: response.data['message'] ?? 'Failed to load vehicle types',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on DioException catch (e) {
      return ApiResult.failure(
        error: e.response?.data['message'] ?? e.message,
        statusCode: e.response?.statusCode ?? 0,
      );
    } catch (e) {
      return ApiResult.failure(
        error: e.toString(),
        statusCode: 0,
      );
    }
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
    final data = {
      'firstname': firstName,
      if (lastName != null) 'lastname': lastName,
      if (phone != null) 'phone': phone.replaceAll("+", ""),
      if (email != null) 'email': email,
    };
    try {
      // Repointed from the dead legacy
      // `/api/v1/dashboard/user/profile/update` path to the whitelisted
      // Frappe defs through the universal platform gateway: Users'
      // `api.user.update_profile` takes the same
      // firstname/lastname/email/phone keys and answers get_profile()'s
      // {"data": {...}} envelope, which ProfileResponse parses as-is. A
      // password change is a separate def on the Frappe side
      // (`api.user.update_password`), so it is issued as its own call
      // first — failing the whole update if the password is rejected,
      // before any profile fields are touched.
      if (password != null) {
        await _gateway.tenant('$_userCmd.update_password', {
          'password': password,
          'password_confirmation': confirmPassword ?? password,
        });
      }
      final response =
          await _gateway.tenant('$_userCmd.update_profile', data);
      return ApiResult.success(
        data: ProfileResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> update profile details failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<DeliveryResponse>> editCarInfo(
      {required String type,
      required String brand,
      required String model,
      required String number,
      required String color,
      required String height,
      required String weight,
      required String length,
      required String width,
      String? imageUrl}) async {
    // Doctype keys of the Deliveryman Profile the whitelisted def
    // writes: the legacy model/number/images[0] become
    // car_model/car_number/vehicle_image.
    final settingsData = {
      'type_of_technique': type,
      'brand': brand,
      'car_model': model,
      'car_number': number,
      'color': color,
      if (height.trim().isNotEmpty) 'height': int.tryParse(height),
      if (width.trim().isNotEmpty) 'width': int.tryParse(width),
      if (weight.trim().isNotEmpty) 'kg': int.tryParse(weight),
      if (length.trim().isNotEmpty) 'length': int.tryParse(length),
      "online": (LocalStorage.getUser()?.active ?? false) ? 1 : 0,
      if (imageUrl != null) 'vehicle_image': imageUrl,
    };
    debugPrint('===> update car info data ${jsonEncode(settingsData)}');
    try {
      // Repointed from the dead legacy POST
      // `/api/v1/dashboard/deliveryman/settings` path to the whitelisted
      // Frappe def (delivery manifest key
      // `api.delivery_man.update_deliveryman_settings`) through the
      // universal platform gateway. The def answers the saved profile's
      // bare dict; folded into the legacy DeliveryResponse client-side.
      final response = await _gateway.tenant(
        '$_deliveryCmd.update_deliveryman_settings',
        {'settings_data': settingsData},
      );
      return ApiResult.success(
        data: _deliveryResponseFromSettings(response),
      );
    } catch (e) {
      debugPrint('==> update car details failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<DeliveryResponse>> createCarInfo(
      {required String type,
      required String brand,
      required String model,
      required String number,
      required String color,
      required String height,
      required String weight,
      required String length,
      required String width,
      String? imageUrl}) async {
    final online = (LocalStorage.getUser()?.active ?? false) ? 1 : 0;
    final carData = {
      "type_of_technique": type,
      "brand": brand,
      "model": model,
      "number": number,
      "color": color,
      'height': int.tryParse(height) ?? 0,
      'width': int.tryParse(width) ?? 0,
      'kg': int.tryParse(weight) ?? 0,
      'length': int.tryParse(length) ?? 0,
      "online": online,
      if (imageUrl != null) 'images': [imageUrl],
    };
    debugPrint('===> create car info data ${jsonEncode(carData)}');
    try {
      // Repointed from the dead legacy POST
      // `/api/v1/dashboard/user/request-models` path to the whitelisted
      // Frappe def (Users manifest key `api.user.create_request_model`)
      // through the universal platform gateway; the car payload rides in
      // the Request Model's `data` field for admin approval, tied to the
      // requesting user via model_type/model_id. The def answers the raw
      // Request Model doc dict (not Data-shaped), so the DeliveryResponse
      // the caller caches is rebuilt from the submitted fields.
      await _gateway.tenant('$_userCmd.create_request_model', {
        'model_type': 'deliveryman',
        'model_id': LocalStorage.getUser()?.id ?? '',
        'data': jsonEncode(carData),
      });
      return ApiResult.success(
        data: DeliveryResponse(
          status: true,
          data: Data(
            typeOfTechnique: type,
            brand: brand,
            model: model,
            number: number,
            color: color,
            height: height,
            width: width,
            kg: weight,
            length: length,
            online: online == 1,
            galleries:
                imageUrl == null ? null : [Galleries(path: imageUrl)],
          ),
        ),
      );
    } catch (e, s) {
      debugPrint('==> create car details failure: $e.$s');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult> setOnline() async {
    try {
      // Repointed from the dead legacy
      // `/api/v1/dashboard/deliveryman/settings/online` toggle to the
      // registered Frappe method (delivery manifest key
      // `api.delivery_man.update_deliveryman_settings`) through the
      // universal platform gateway. The legacy endpoint flipped the flag
      // server-side; the Frappe def takes the desired value, so the
      // toggle is expressed from the same local cache the only caller
      // (home_notifier.setOnline) flips on success.
      await _gateway.tenant('api.delivery_man.update_deliveryman_settings', {
        'settings_data': {'online': CourierStorage.getOnline() ? 0 : 1},
      });
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> update online token failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<RequestModelResponse>> getRequestModel() async {
    try {
      // Repointed from the dead legacy GET
      // `/api/v1/dashboard/user/request-models` path to the whitelisted
      // Frappe def (Users manifest key `api.user.get_user_request_models`)
      // through the universal platform gateway. Rows are normalized
      // before parsing (_normalizeRequestModelRow) because the Frappe
      // rows differ from the Laravel ones RequestModelData was written
      // for: `data` arrives JSON-encoded, `model` is a Link name string
      // (not a profile map), and Frappe docnames are hash strings that
      // cannot fill the legacy int `id`/`model_id`.
      final res = await _gateway.tenant(
        '$_userCmd.get_user_request_models',
        {'start': 0, 'limit': 20},
      );
      final body =
          res is Map ? Map<String, dynamic>.from(res) : <String, dynamic>{};
      final rows = body['data'];
      final normalized = <Map<String, dynamic>>[
        if (rows is List)
          for (final row in rows)
            if (row is Map) _normalizeRequestModelRow(row),
      ];
      return ApiResult.success(
        data: RequestModelResponse.fromJson({...body, 'data': normalized}),
      );
    } catch (e) {
      debugPrint('==> get request model failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  /// Makes a Frappe Request Model row safe for the legacy
  /// [RequestModelData.fromJson]: decodes a JSON-string `data` payload,
  /// drops link-name strings from the profile-map fields and drops
  /// non-int ids (Frappe docnames are hash strings) or unparseable
  /// timestamps rather than letting the legacy parser throw.
  static Map<String, dynamic> _normalizeRequestModelRow(Map row) {
    final out = Map<String, dynamic>.from(row);
    final data = out['data'];
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          out['data'] = Map<String, dynamic>.from(decoded);
        } else {
          out.remove('data');
        }
      } catch (_) {
        out.remove('data');
      }
    } else if (data is! Map) {
      out.remove('data');
    }
    for (final key in ['id', 'model_id']) {
      if (out[key] is! int) out.remove(key);
    }
    for (final key in ['model', 'createdBy']) {
      if (out[key] is! Map) out.remove(key);
    }
    for (final key in ['created_at', 'updated_at']) {
      final value = out[key];
      if (value != null && DateTime.tryParse(value.toString()) == null) {
        out.remove(key);
      }
    }
    return out;
  }

  @override
  Future<ApiResult> setCurrentLocation(LatLng location) async {
    try {
      // Rewired from the dead legacy
      // `/api/v1/dashboard/deliveryman/settings/location` path to the
      // working Frappe endpoint (writes Deliveryman Profile
      // latitude/longitude), now through the universal platform gateway.
      // The response is a plain status payload, not the legacy
      // DeliveryResponse, so nothing is cached here anymore.
      await _gateway.tenant(
        'api.driver.update_location',
        {
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
      );
      return const ApiResult.success(
        data: null,
      );
    } catch (e, s) {
      debugPrint('===> error location settings $e,$s');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<List<List<double>>>> getDeliveryZone() async {
    try {
      // Repointed from the dead legacy
      // `/api/v1/dashboard/deliveryman/delivery-zones` path to the
      // whitelisted Frappe def (delivery manifest key
      // `api.delivery_man.get_deliveryman_zone_polygon`, reading the
      // polygon stored on the Deliveryman Profile) through the universal
      // platform gateway. The def answers {"data": [[lat, lng], ...]}
      // with an empty list when no polygon is drawn yet — the same
      // envelope the legacy parse below already handled. (The older
      // `get_deliveryman_delivery_zones` def returns Delivery Zone link
      // names, not coordinates — wrong shape for this facade.)
      final response = await _gateway
          .tenant('$_deliveryCmd.get_deliveryman_zone_polygon');
      final body = response is Map ? response['data'] : null;
      final List<List<double>> zone = body == null
          ? []
          : List<List<double>>.from((body as List).map(
              (x) => List<double>.from((x as List).map(
                    (v) => (v as num).toDouble(),
                  ))));
      return ApiResult.success(data: zone);
    } catch (e) {
      debugPrint('===> error get delivery zone $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }
}
