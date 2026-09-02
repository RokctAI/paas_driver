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

import 'package:flutter/material.dart';

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

import 'package:delivery_sdk/src/driver/domain/interface/route.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/route_stop.dart';

/// Frappe-backed driver route repository. The server is authoritative
/// for stop ordering; this class only fetches and parses.
///
/// Calls go through the universal platform gateway ([PlatformGateway]);
/// the prefix-free cmds mirror the owning modules' `manifest.json`
/// whitelisted-method keys (map's `api.driver_order.get_driver_route`,
/// delivery's `api.dispatch_route.*`). FrappeResponseInterceptor already
/// unwraps the top-level `message` key, so each gateway answer is the
/// endpoint's payload itself (a JSON list for get_driver_route, an
/// envelope map for the dispatch route).
class CourierRouteRepository implements CourierRouteRepositoryFacade {
  static const _gateway = PlatformGateway();

  @override
  Future<ApiResult<List<RouteStopData>>> getDriverRoute({
    double? latitude,
    double? longitude,
  }) async {
    final data = {
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
    try {
      final response =
          await _gateway.tenant('api.driver_order.get_driver_route', data);
      return ApiResult.success(
        data: RouteStopData.listFromJson(response),
      );
    } catch (e) {
      debugPrint('==> get driver route failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<DispatchRouteResponse>> getMyDispatchRoute() async {
    try {
      final response =
          await _gateway.tenant('api.dispatch_route.get_my_dispatch_route');
      return ApiResult.success(
        data: DispatchRouteResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> get dispatch route failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<dynamic>> completeDispatchStop({
    required String routeId,
    required String stopName,
    String status = 'Done',
  }) async {
    try {
      final response = await _gateway.tenant(
        'api.dispatch_route.complete_dispatch_stop',
        {
          'route_id': routeId,
          'stop_name': stopName,
          'status': status,
        },
      );
      return ApiResult.success(data: response);
    } catch (e) {
      debugPrint('==> complete dispatch stop failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }
}
