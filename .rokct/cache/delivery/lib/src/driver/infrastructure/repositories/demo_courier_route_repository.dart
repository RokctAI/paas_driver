// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
