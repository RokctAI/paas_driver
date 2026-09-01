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

import 'package:delivery_sdk/src/driver/domain/interface/route.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/route_stop.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/demo_delivery_seed.dart';

/// Demo-only [CourierRouteRepositoryFacade] (`--dart-define=IS_DEMO=true`):
/// serves the fictional [DemoDeliverySeed] dispatch route offline through
/// the same parsers the HTTP repository uses. Registered in place of
/// [CourierRouteRepository] by DriverDeliveryDependencies when demo mode is
/// on. Never used in production.
class DemoCourierRouteRepository implements CourierRouteRepositoryFacade {
  /// Session-local stop completion (stop ref_name -> Done/Skipped), so
  /// ticking off a demo stop sticks for the rest of the run.
  static final Map<String, String> _stopStatusOverlay = {};

  List<Map<String, dynamic>> _stopsWithOverlay() =>
      DemoDeliverySeed.routeStops().map((s) {
        final overlay = _stopStatusOverlay['${s['ref_name']}'];
        if (overlay != null) s['status'] = overlay;
        return s;
      }).toList();

  @override
  Future<ApiResult<List<RouteStopData>>> getDriverRoute({
    double? latitude,
    double? longitude,
  }) async {
    return ApiResult.success(
      data: RouteStopData.listFromJson(_stopsWithOverlay()),
    );
  }

  @override
  Future<ApiResult<DispatchRouteResponse>> getMyDispatchRoute() async {
    final stops = _stopsWithOverlay();
    final pending =
        stops.where((s) => (s['status'] ?? 'Pending') == 'Pending').length;
    final route = DemoDeliverySeed.dispatchRoute();
    (route['route'] as Map<String, dynamic>)['pending_stops'] = pending;
    route['stops'] = stops;
    return ApiResult.success(data: DispatchRouteResponse.fromJson(route));
  }

  @override
  Future<ApiResult<dynamic>> completeDispatchStop({
    required String routeId,
    required String stopName,
    String status = 'Done',
  }) async {
    _stopStatusOverlay[stopName] = status;
    return const ApiResult.success(data: true);
  }
}
