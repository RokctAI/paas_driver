import 'package:base_sdk/base_sdk.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:zones_sdk/zones_sdk.dart';

// Prefixed for symmetry with the driver adapter: base_sdk's injection.dart
// exports repository getters of its own, and a prefix keeps every reference
// to the host's dependency_manager unambiguous.
import 'package:${package}/domain/di/dependency_manager.dart' as di;

/// Host-side wiring for zones_sdk in the manager flavour (ADR-005).
///
/// zones_sdk owns delivery-zone geometry but must not import whichever SDK
/// stores the shop's data, so it declares a narrow seam and the host app
/// supplies the implementation. This file is host-composition code — it lives
/// in templates/ and is installed into the app at compose time (manager
/// flavour only, see manifest.json app_type.manager), which is why it may
/// reference both zones_sdk and the app's own repositories. The validator
/// scans SDK lib/ only, so nothing here is a cross-SDK import violation.
///
/// Register in the host's main(), OUTSIDE the @generated-sdk-di markers:
///
///   await setUpDependencies();
///   GetIt.instance.registerLazySingleton<DeliveryZonesFacade>(
///     () => ManagerDeliveryZonesAdapter());
///
/// Order matters: setUpDependencies() must run first, since the adapter
/// resolves the users repository. Without this registration
/// deliveryZoneProvider falls back to a 501 "not wired" stand-in and the zone
/// screen never reaches real shop data.
///
/// No ZoneEditPolicy registration, deliberately: a merchant drawing their own
/// shop's catchment has no equivalent of the driver's
/// `driver_can_edit_credentials` restriction, and registering nothing is the
/// contract's explicit way to say "unrestricted".

/// Binds zones_sdk's zone read/write to the manager app's users repository.
///
/// The polygon is persisted against the merchant's shop (legacy Laravel
/// endpoint `/api/v1/dashboard/seller/delivery-zones`, shop_id-scoped), which
/// is why this lives in the host: only the app knows which repository holds
/// it. The paginate response carries a list of zones; the seller dashboard
/// only ever edits the first (the app fetches with perPage: 1), so the first
/// zone's polygon is the facade's whole answer.
class ManagerDeliveryZonesAdapter implements DeliveryZonesFacade {
  @override
  Future<ApiResult<List<List<double>>>> fetchDeliveryZones() async {
    final response = await di.usersRepository.getDeliveryZone();
    return response.when(
      success: (paginate) => ApiResult.success(
        data: paginate.data?.isNotEmpty == true
            ? (paginate.data!.first.address ?? const <List<double>>[])
            : const <List<double>>[],
      ),
      failure: (error, statusCode) =>
          ApiResult.failure(error: error, statusCode: statusCode),
    );
  }

  @override
  Future<ApiResult<void>> updateDeliveryZones({
    required List<List<double>> points,
  }) async {
    // The host repository returns its own ApiResult class
    // (package:manager/domain/handlers), which is a different type from
    // base_sdk's ApiResult in the facade signature, so the result must be
    // unwrapped and rebuilt — same bridging fetchDeliveryZones does above.
    final response = await di.usersRepository.updateDeliveryZones(
      points: points.map((p) => LatLng(p[0], p[1])).toList(),
    );
    return response.when(
      success: (_) => const ApiResult.success(data: null),
      failure: (error, statusCode) =>
          ApiResult.failure(error: error, statusCode: statusCode),
    );
  }
}
