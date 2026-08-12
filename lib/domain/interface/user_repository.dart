// Shrunken to the single seam that still needs a host-owned repository
// (migration stage M3): zones_sdk's installed driver adapter
// (lib/presentation/routes/zones_adapters.dart) resolves the courier's
// delivery-zone polygon through `di.userRepository` - see
// domain/di/dependency_manager.dart for the exit plan.
//
// The auth-flip stage deleted the rest of the M2 surface with its callers:
// updateFirebaseToken (host login/sign-up notifiers) and
// getRequestModel/deleteAccount (host profile-settings notifier) died with
// the host auth vertical; auth_sdk and delivery_sdk own those flows now.
//
// ProfileZoneResponse below replaces the deleted host ProfileResponse/
// UserData pair with just the slice the adapter reads
// (`data?.deliveryZone`); the adapter binds to this repository's declared
// return type through inference, so no shared model import is needed.
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:base_sdk/src/handlers/handlers.dart';

/// The delivery-zone slice of the courier's profile record.
class ProfileZoneResponse {
  ProfileZoneResponse({this.data});

  ProfileZoneResponse.fromJson(dynamic json)
      : data = json?['data'] != null
            ? ProfileZoneData.fromJson(json['data'])
            : null;

  final ProfileZoneData? data;
}

class ProfileZoneData {
  ProfileZoneData({this.deliveryZone});

  /// Parsed exactly as the deleted host UserData did: the polygon is stored
  /// on the courier's profile as `delivery_man_delivery_zone`, a list of
  /// [lat, lng] pairs; null means "no zone drawn yet".
  ProfileZoneData.fromJson(dynamic json)
      : deliveryZone = json?['delivery_man_delivery_zone'] == null
            ? const <List<double>>[]
            : List<List<double>>.from(json['delivery_man_delivery_zone']!.map(
                (x) => List<double>.from(x.map((y) => (y as num?)?.toDouble())),
              ));

  final List<List<double>>? deliveryZone;
}

abstract class UserRepository {
  Future<ApiResult<ProfileZoneResponse>> getProfileDetails();

  Future<ApiResult<void>> updateDeliveryZones({
    required List<LatLng> points,
  });
}
