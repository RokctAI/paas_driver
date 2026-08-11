import 'package:base_sdk/src/handlers/api_result.dart';

/// zones_sdk's consumer-owned view of whoever stores a courier's served area
/// (ADR-005).
///
/// The zone polygon is persisted against the courier's own profile record, so
/// the natural provider is the SDK that owns user/profile data. zones_sdk must
/// not import that package directly, and shouldn't have to: it needs exactly
/// two operations and one data shape, not a profile model.
///
/// The shape is deliberately primitive — an ordered list of `[latitude,
/// longitude]` pairs describing a closed polygon. Using plain doubles rather
/// than a map type keeps this interface free of `google_maps_flutter` too, so
/// a non-map host (or a test) can implement it with no plugin dependency. The
/// notifier converts to/from `LatLng` at the edge.
///
/// The host app supplies the implementation via DI at startup. Where nothing
/// is registered, callers should treat delivery zones as unavailable rather
/// than failing — see [ZonesSdkDependencies].
abstract class DeliveryZonesFacade {
  /// The courier's currently-saved zone, or an empty list when they have not
  /// drawn one yet.
  Future<ApiResult<List<List<double>>>> fetchDeliveryZones();

  /// Replaces the courier's saved zone with [points].
  ///
  /// Callers pass the polygon in the order the courier drew it; closing the
  /// ring is the server's concern, not this interface's.
  Future<ApiResult<void>> updateDeliveryZones({
    required List<List<double>> points,
  });
}
