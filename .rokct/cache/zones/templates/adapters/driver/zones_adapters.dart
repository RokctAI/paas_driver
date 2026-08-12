import 'package:base_sdk/base_sdk.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:zones_sdk/zones_sdk.dart';

// Prefixed: base_sdk's injection.dart also exports a `userRepository`, and an
// unprefixed import makes every reference to it ambiguous.
import 'package:${package}/domain/di/dependency_manager.dart' as di;

/// Host-side wiring for zones_sdk (ADR-005).
///
/// zones_sdk owns delivery-zone geometry but must not import whichever SDK
/// stores the courier's profile, so it declares two narrow seams and the host
/// app supplies both. This file is host-composition code — it lives in
/// templates/ and is installed into the app at compose time (driver flavour
/// only, see manifest.json app_type.driver), which is why it may reference
/// both zones_sdk and the app's own repositories. The validator scans SDK
/// lib/ only, so nothing here is a cross-SDK import violation.
///
/// Register both in the host's main(), OUTSIDE the @generated-sdk-di markers:
///
///   await setUpDependencies();
///   GetIt.instance.registerLazySingleton<DeliveryZonesFacade>(
///     () => DriverDeliveryZonesAdapter());
///   GetIt.instance.registerLazySingleton<ZoneEditPolicy>(
///     () => DriverZoneEditPolicy());
///
/// Order matters: setUpDependencies() must run first, since the adapter
/// resolves UserRepository. Without these registrations deliveryZoneProvider
/// falls back to a 501 "not wired" stand-in and the zone screen never reaches
/// real profile data.

/// Binds zones_sdk's zone read/write to the driver's own user repository.
///
/// The polygon is persisted on the courier's profile record
/// (`delivery_man_delivery_zone`), which is why this lives in the host: only
/// the app knows which repository holds it.
class DriverDeliveryZonesAdapter implements DeliveryZonesFacade {
  @override
  Future<ApiResult<List<List<double>>>> fetchDeliveryZones() async {
    final response = await di.userRepository.getProfileDetails();
    return response.when(
      success: (data) => ApiResult.success(
        data: data.data?.deliveryZone ?? const <List<double>>[],
      ),
      failure: (error, statusCode) =>
          ApiResult.failure(error: error, statusCode: statusCode),
    );
  }

  @override
  Future<ApiResult<void>> updateDeliveryZones({
    required List<List<double>> points,
  }) async {
    // The host repository declares its own ApiResult type (today it happens
    // to be base_sdk's, which is why the old pass-through compiled), but the
    // facade must not depend on that, so the result is unwrapped and rebuilt
    // — same bridging fetchDeliveryZones does above.
    final response = await di.userRepository.updateDeliveryZones(
      points: points.map((p) => LatLng(p[0], p[1])).toList(),
    );
    return response.when(
      success: (_) => const ApiResult.success(data: null),
      failure: (error, statusCode) =>
          ApiResult.failure(error: error, statusCode: statusCode),
    );
  }
}

/// The driver flavour's rule for who may redraw a zone.
///
/// Operators who assign routes centrally set `driver_can_edit_credentials` to
/// "0", making the zone map read-only. A missing setting means allowed — the
/// permissive default matches pre-fork behaviour, where the flag had to be
/// explicitly "0" to lock editing.
///
/// Host-side rather than in zones_sdk: this setting is a driver-app concept,
/// and a merchant editing their own shop catchment has no equivalent
/// restriction. Registering nothing is how a flavour says "unrestricted".
class DriverZoneEditPolicy implements ZoneEditPolicy {
  @override
  bool canEdit() {
    for (final setting in LocalStorage.getSettingsList()) {
      if (setting.key == 'driver_can_edit_credentials') {
        return setting.value != '0';
      }
    }
    return true;
  }
}
