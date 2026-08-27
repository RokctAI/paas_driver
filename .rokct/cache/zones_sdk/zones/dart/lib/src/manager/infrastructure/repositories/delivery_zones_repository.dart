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
import 'package:base_sdk/src/services/local_storage.dart';

import 'package:zones_sdk/src/common/domain/interface/delivery_zones.dart';

/// The manager (merchant) flavour's own [DeliveryZonesFacade] implementation
/// over base_sdk's HTTP infrastructure.
///
/// Absorbed from paas_manager's retired host users-repository delivery-zone
/// slice (lib/infrastructure/repositories/users_repository.dart, manager
/// migration M5): the shop's catchment polygon is persisted against the
/// merchant's shop (legacy Laravel endpoint
/// `/api/v1/dashboard/seller/delivery-zones`, shop_id-scoped). With the
/// endpoint knowledge living HERE, no host-owned repository remains — the
/// installed manager zones_adapters.dart is a thin shim over this class,
/// registered via the manifest's app_type.manager di_hooks entry.
///
/// Repointed from the dead legacy `/api/v1/dashboard/seller/delivery-zones`
/// endpoint pair to the registered Frappe methods of the zones module
/// (manifest keys `api.delivery_zone.get_shop_delivery_zones` /
/// `create_delivery_zone` / `update_delivery_zone`) through the universal
/// platform gateway. The Delivery Zone doctype stores the polygon in two
/// Code (JSON string) columns: `address` keeps the client's own
/// `[latitude, longitude]` pair list (round-tripped verbatim by this
/// repository), and `coordinates` keeps the same ring in the GeoJSON
/// `[longitude, latitude]` order that the backend's
/// check_delivery_availability point-in-polygon test reads. The seller
/// dashboard only ever edits one zone, so the first zone answers the
/// facade and the write upserts it (update when a zone exists, create
/// otherwise).
class ManagerDeliveryZonesRepository implements DeliveryZonesFacade {
  static const _gateway = PlatformGateway();

  /// The shop's zones as raw rows from the gateway (already
  /// interceptor-unwrapped: the answer is the list itself).
  Future<List<dynamic>> _fetchZoneRows() async {
    final response = await _gateway.tenant(
      'api.delivery_zone.get_shop_delivery_zones',
      {'shop_id': LocalStorage.getShopJson()?['id']},
    );
    return response is List ? response : const [];
  }

  /// Decodes a Delivery Zone row's `address` Code column ([lat, lng]
  /// pair list stored as a JSON string) into the facade's primitive
  /// shape. Tolerates an already-decoded list and malformed content.
  static List<List<double>> _decodeAddress(dynamic address) {
    dynamic decoded = address;
    if (decoded is String) {
      if (decoded.trim().isEmpty) return const [];
      try {
        decoded = jsonDecode(decoded);
      } catch (_) {
        return const [];
      }
    }
    if (decoded is! List) return const [];
    return decoded
        .whereType<List<dynamic>>()
        .map((point) => point
            .map((coordinate) => double.parse(coordinate.toString()))
            .toList())
        .toList();
  }

  @override
  Future<ApiResult<List<List<double>>>> fetchDeliveryZones() async {
    try {
      final zones = await _fetchZoneRows();
      if (zones.isEmpty) {
        return const ApiResult.success(data: <List<double>>[]);
      }
      return ApiResult.success(
        data: _decodeAddress(zones.first['address']),
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
    final zoneData = {
      'address': jsonEncode([
        for (final point in points) [point[0], point[1]],
      ]),
      // GeoJSON [lng, lat] order — what check_delivery_availability reads.
      'coordinates': jsonEncode([
        for (final point in points) [point[1], point[0]],
      ]),
    };
    debugPrint('====> update delivery zone ${jsonEncode(zoneData)}');
    try {
      final zones = await _fetchZoneRows();
      if (zones.isEmpty) {
        await _gateway.tenant('api.delivery_zone.create_delivery_zone', {
          'data': {
            'shop': LocalStorage.getShopJson()?['id'],
            ...zoneData,
          },
        });
      } else {
        await _gateway.tenant('api.delivery_zone.update_delivery_zone', {
          'name': zones.first['name'],
          'data': zoneData,
        });
      }
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
