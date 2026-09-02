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

import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/handlers/api_result.dart';

import 'package:zones_sdk/src/common/domain/interface/delivery_zones.dart';

/// Demo-only [DeliveryZonesFacade] (`--dart-define=IS_DEMO=true`): serves a
/// fictional courier zone polygon offline, so the driver /delivery-zone
/// editor is never an empty grey map in demo builds. Served in place of
/// DriverDeliveryZonesRepository's HTTP path by the installed driver
/// `zones_adapters.dart` — the same `AppConstants.isDemo` split delivery_sdk's
/// `DriverDeliveryDependencies` applies to every courier facade
/// (DemoLmsRepository precedent). Never used in production; every write is
/// acknowledged locally and nothing leaves the device.
///
/// The seed square deliberately mirrors delivery_sdk's
/// `DemoDeliverySeed.deliveryZone()` (same ±0.030° offsets around the same
/// demo anchor), so the zone the courier sees on the home map and the zone
/// this editor opens on are the same shape. Duplicated rather than imported:
/// zones_sdk must not depend on delivery_sdk (ADR-005 keeps the facade free
/// of cross-SDK imports), and five coordinate pairs are cheaper than a new
/// seam.
class DemoDriverDeliveryZonesRepository implements DeliveryZonesFacade {
  /// Demo map anchor. Falls back to a generic Johannesburg city-centre
  /// coordinate when the host build did not define DEMO_LATITUDE /
  /// DEMO_LONGITUDE (AppConstants parses those defines eagerly and throws
  /// on absence) — the exact guard DemoDeliverySeed uses.
  static double get _anchorLatitude {
    try {
      return AppConstants.demoLatitude;
    } catch (_) {
      return -26.2041;
    }
  }

  static double get _anchorLongitude {
    try {
      return AppConstants.demoLongitude;
    } catch (_) {
      return 28.0473;
    }
  }

  /// Session-local zone: seeded lazily on first read, replaced by
  /// [updateDeliveryZones] so a redraw sticks for the rest of the session.
  /// Never persisted; resets on every launch (DemoDeliverySeed overlay
  /// convention).
  static List<List<double>>? _zone;

  static List<List<double>> _seedZone() => [
        [_anchorLatitude + 0.030, _anchorLongitude - 0.030],
        [_anchorLatitude + 0.030, _anchorLongitude + 0.030],
        [_anchorLatitude - 0.030, _anchorLongitude + 0.030],
        [_anchorLatitude - 0.030, _anchorLongitude - 0.030],
        [_anchorLatitude + 0.030, _anchorLongitude - 0.030],
      ];

  static void reset() => _zone = null;

  @override
  Future<ApiResult<List<List<double>>>> fetchDeliveryZones() async {
    _zone ??= _seedZone();
    return ApiResult.success(data: _zone!);
  }

  @override
  Future<ApiResult<void>> updateDeliveryZones({
    required List<List<double>> points,
  }) async {
    _zone = [
      for (final point in points) List<double>.from(point),
    ];
    return const ApiResult.success(data: null);
  }
}
