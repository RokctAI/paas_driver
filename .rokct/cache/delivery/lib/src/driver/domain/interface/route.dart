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

abstract class CourierRouteRepositoryFacade {
  /// The merged, server-ordered stop list (active orders + parcels +
  /// dispatch-route stops). Latitude/longitude seed the optimizer with
  /// the driver's live position when available.
  Future<ApiResult<List<RouteStopData>>> getDriverRoute({
    double? latitude,
    double? longitude,
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
