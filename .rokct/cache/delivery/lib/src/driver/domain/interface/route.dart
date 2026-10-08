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

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/route_stop.dart';

/// WHICH STOPS a route read is asking for.
///
/// Both answers come back as the same [RouteStopData] list, ordered by the
/// same server-side optimiser, which is why this is an argument on one
/// repository rather than a second page: the driver is looking at a
/// numbered list of places to drive to either way.
enum DriverRouteSource {
  /// The day's work: the driver's active orders and parcels plus the
  /// pending stops of his dispatch route (map's
  /// `api.driver_order.get_driver_route`).
  work,

  /// The round's knowledge: the points of interest in scope, ordered as a
  /// drive (map's `api.poi.get_poi_route`). No pickups, no money, nothing
  /// to complete — places worth passing.
  pois,
}

abstract class CourierRouteRepositoryFacade {
  /// The merged, server-ordered stop list. [source] picks WHICH stops:
  /// the day's work (active orders + parcels + dispatch-route stops) or the
  /// round's points of interest. Latitude/longitude seed the optimizer with
  /// the driver's live position when available.
  Future<ApiResult<List<RouteStopData>>> getDriverRoute({
    double? latitude,
    double? longitude,
    DriverRouteSource source = DriverRouteSource.work,
  });

  /// The active admin-composed Dispatch Route (header + ordered stops),
  /// or an empty response when none is assigned.
  Future<ApiResult<DispatchRouteResponse>> getMyDispatchRoute();

  /// Marks a dispatch stop Done or Skipped (idempotent server-side).
  Future<ApiResult<dynamic>> completeDispatchStop({
    required String routeId,
    required String stopName,
    String status = 'Done',
  });
}
