// Copyright (c) 2026 RokctAI
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

import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/handlers/network_exceptions.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

import 'package:zones_sdk/src/common/domain/interface/delivery_zones.dart';

/// The driver (courier) flavour's own [DeliveryZonesFacade] implementation
/// over base_sdk's HTTP infrastructure.
///
/// Absorbed from paas_driver's retired host user-repository delivery-zone
/// slice (lib/infrastructure/repositories/user_repository_impl.dart, driver
/// migration M4 — the exact mirror of zones#11's
/// ManagerDeliveryZonesRepository): the courier's zone polygon is persisted
/// on their own profile record as `delivery_man_delivery_zone` (legacy
/// Laravel endpoints, see paas_driver's docs/fork-endpoint-handoff.md —
/// `/api/v1/dashboard/user/profile/show` to read,
/// `/api/v1/dashboard/deliveryman/delivery-zones` to write). With the
/// endpoint knowledge living HERE, no host-owned repository remains — the
/// installed driver zones_adapters.dart is a thin shim over this class,
/// registered via the manifest's app_type.driver di_hooks entry.
///
/// The profile response stores the polygon as a list of
/// `[latitude, longitude]` pairs; null means "no zone drawn yet", which the
/// facade contract expresses as an empty list.
class DriverDeliveryZonesRepository implements DeliveryZonesFacade {
  @override
  Future<ApiResult<List<List<double>>>> fetchDeliveryZones() async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get('/api/v1/dashboard/user/profile/show');
      final dynamic zone = response.data?['data']?['delivery_man_delivery_zone'];
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
    final data = {
      'address': [
        for (final point in points) {'0': point[0], '1': point[1]},
      ],
    };
    debugPrint('====> update delivery zone ${jsonEncode(data)}');
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/v1/dashboard/deliveryman/delivery-zones',
        data: data,
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
