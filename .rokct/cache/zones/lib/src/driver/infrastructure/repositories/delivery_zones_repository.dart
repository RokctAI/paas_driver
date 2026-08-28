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

import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/handlers/network_exceptions.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

import 'package:zones_sdk/src/common/domain/interface/delivery_zones.dart';

/// The driver (courier) flavour's own [DeliveryZonesFacade] implementation
/// over base_sdk's HTTP infrastructure.
///
/// Absorbed from paas_driver's retired host user-repository delivery-zone
/// slice (lib/infrastructure/repositories/user_repository_impl.dart, driver
/// migration M4 — the exact mirror of zones#11's
/// ManagerDeliveryZonesRepository), then repointed off the dead Laravel
/// endpoints (`/api/v1/dashboard/user/profile/show` to read,
/// `/api/v1/dashboard/deliveryman/delivery-zones` to write) onto the
/// whitelisted Frappe defs through the universal platform gateway: the
/// courier's working-area polygon now lives in the
/// `delivery_zone_polygon` field on his own Deliveryman Profile, served
/// by delivery's `api.delivery_man.get_deliveryman_zone_polygon` /
/// `set_deliveryman_zone_polygon` manifest keys. With the endpoint
/// knowledge living HERE, no host-owned repository remains — the
/// installed driver zones_adapters.dart is a thin shim over this class,
/// registered via the manifest's app_type.driver di_hooks entry.
///
/// Both defs speak plain `[[latitude, longitude], ...]` pair lists inside
/// a {"data": ...} envelope; an empty list means "no zone drawn yet",
/// which the facade contract also expresses as an empty list.
class DriverDeliveryZonesRepository implements DeliveryZonesFacade {
  static const _gateway = PlatformGateway();

  /// Prefix-free cmd base for the universal platform gateway: delivery's
  /// `manifest.json` whitelisted-method keys
  /// (`{app_name}.api.delivery_man.*`) with the app segment dropped.
  static const _cmd = 'api.delivery_man';

  @override
  Future<ApiResult<List<List<double>>>> fetchDeliveryZones() async {
    try {
      final response =
          await _gateway.tenant('$_cmd.get_deliveryman_zone_polygon');
      final dynamic zone = response is Map ? response['data'] : null;
      if (zone == null) {
        return const ApiResult.success(data: <List<double>>[]);
      }
      return ApiResult.success(
        data: (zone as List<dynamic>)
            .map((point) => (point as List<dynamic>)
                .map((coordinate) => double.parse(coordinate.toString()))
                .toList())
            .toList(),
      );
    } catch (e) {
      debugPrint('==> get delivery zone failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<void>> updateDeliveryZones({
    required List<List<double>> points,
  }) async {
    // The def takes the polygon as plain [[lat, lng], ...] pairs (the
    // legacy {'0': lat, '1': lng} address shape is gone with the Laravel
    // endpoint).
    debugPrint('====> update delivery zone ${jsonEncode(points)}');
    try {
      await _gateway.tenant(
        '$_cmd.set_deliveryman_zone_polygon',
        {'points': points},
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> update delivery zones failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}
