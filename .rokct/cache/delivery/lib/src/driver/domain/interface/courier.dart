import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/models/response/driver_show_response.dart';
import 'package:base_sdk/src/models/response/profile_response.dart';

import 'package:delivery_sdk/src/driver/infrastructure/models/data/delivery_vehicle_type.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/response/request_model_response.dart';

/// The courier (deliveryman) slice of paas_driver's legacy `UserRepository`:
/// vehicle details, online/location reporting, the become-a-courier request
/// funnel, and the courier's own zone read. Moved AS-IS from the host per
/// decision D2 (Laravel `/api/v1/dashboard/deliveryman/*` endpoints stay
/// Laravel; the Frappe port is separate backend scope).
///
/// The generic profile methods the legacy repository also carried
/// (getProfileDetails / updateProfileImage / deleteAccount / ...) are NOT
/// duplicated here — base_sdk's [UserRepositoryFacade] already declares them
/// and users_sdk registers the implementation in every driver compose. The
/// zone WRITE (updateDeliveryZones) stays behind zones_sdk's
/// `DeliveryZonesFacade` host seam and is deliberately absent.
abstract class CourierRepositoryFacade {
  Future<ApiResult<DeliveryResponse>> getDriverDetails();

  Future<ApiResult<List<DeliveryVehicleType>>> getDeliveryVehicleTypes();

  /// Courier profile update — the legacy `updateGeneralInfo` shape
  /// (firstname/lastname/phone/email/password), kept verbatim because
  /// base_sdk's `editProfile(EditProfile)` speaks a different body.
  Future<ApiResult<ProfileResponse>> updateGeneralInfo({
    required String firstName,
    String? lastName,
    String? phone,
    String? email,
    String? password,
    String? confirmPassword,
  });

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
  });

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
  });

  Future<ApiResult<RequestModelResponse>> getRequestModel();

  Future<ApiResult<dynamic>> setOnline();

  Future<ApiResult<dynamic>> setCurrentLocation(LatLng location);

  /// The courier's zone polygon, as the flat coordinate list the map layer
  /// consumes (the legacy host returned its `DeliveryZonePaginate` wrapper,
  /// whose model now lives in zones_sdk — returning the unwrapped list keeps
  /// this SDK free of cross-SDK imports, Ray's base_sdk-only rule).
  Future<ApiResult<List<List<double>>>> getDeliveryZone();
}
