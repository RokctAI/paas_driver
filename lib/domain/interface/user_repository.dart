// Shrunken in migration stage M2 to the slice the surviving host code still
// calls:
//
//  - getProfileDetails / updateDeliveryZones: resolved by zones_sdk's
//    installed driver adapter (lib/presentation/routes/zones_adapters.dart)
//    via `di.userRepository` - the ADR-005 seam that outlives M3 (exit plan
//    in domain/di/dependency_manager.dart);
//  - updateFirebaseToken: the host login/sign-up notifiers save the FCM
//    token post-auth (dies with the auth flip, M3);
//  - getRequestModel / deleteAccount: the profile-settings notifier the
//    host register funnel still uses (dies with M3).
//
// Everything else (driver details, vehicles, car info, online toggle,
// location report, profile edit) moved to delivery_sdk's src/driver
// repositories with the courier vertical. The statistics slice moved to
// revenue_sdk's CourierStatisticsRepositoryFacade earlier (corporate main).
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:base_sdk/src/handlers/handlers.dart';

import '../../infrastructure/models/response/profile_response.dart';
import '../../infrastructure/models/response/request_model_response.dart';

abstract class UserRepository {
  Future<ApiResult<ProfileResponse>> getProfileDetails();

  Future<ApiResult<RequestModelResponse>> getRequestModel();

  Future<ApiResult<dynamic>> deleteAccount();

  Future<ApiResult<void>> updateFirebaseToken(String? token);

  Future<ApiResult<void>> updateDeliveryZones({
    required List<LatLng> points,
  });
}
