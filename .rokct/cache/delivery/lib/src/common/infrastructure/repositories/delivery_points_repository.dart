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
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/handlers/network_exceptions.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/domain/interface/delivery_points.dart';
import 'package:base_sdk/src/models/data/delivery_point_data.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

class DeliveryPointsRepository implements DeliveryPointsRepositoryFacade {
  static const _gateway = PlatformGateway();

  /// Fetches delivery points near a specific location.
  @override
  Future<ApiResult<List<DeliveryPointData>>> getDeliveryPoints({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Repointed from the dead direct
      // `/api/method/paas.doctype.delivery_point.delivery_point.get_nearest_delivery_points`
      // path (a dotted name registered in no manifest) onto the universal
      // platform gateway. The prefix-free cmd mirrors delivery's
      // `manifest.json` whitelisted-method key
      // `{app_name}.api.delivery.get_nearest_delivery_points`, aliased in
      // the same change so this SDK's Dart half is answered by its own
      // frappe half (merchants' `api.shop.get_nearest_delivery_points`
      // twin would have crossed SDK lines). The def is guest-readable like
      // its get_delivery_points sibling, so the guest client is kept.
      // FrappeResponseInterceptor already unwraps the top-level `message`
      // key, so the gateway answer is the list itself.
      final response = await _gateway.call(
        'api.delivery.get_nearest_delivery_points',
        payload: {'latitude': latitude, 'longitude': longitude},
        requireAuth: false,
      );
      final List<dynamic> data = response;
      final List<DeliveryPointData> deliveryPoints =
          data.map((e) => DeliveryPointData.fromJson(e)).toList();
      return ApiResult.success(data: deliveryPoints);
    } catch (e) {
      debugPrint('==> get delivery points failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  /// Fetches all active delivery points, regardless of location.
  @override
  Future<ApiResult<List<DeliveryPointData>>> getAllDeliveryPoints() async {
    try {
      // Guest endpoint (backend is `@frappe.whitelist(allow_guest=True)`),
      // called through the universal platform gateway — the prefix-free cmd
      // mirrors delivery's `manifest.json` whitelisted-method key
      // `{app_name}.api.delivery.get_delivery_points`. The old direct path
      // used a short dotted name (`paas.api.get_delivery_points`) that is
      // registered nowhere. FrappeResponseInterceptor already unwraps the
      // top-level `message` key, so the gateway answer is the list itself.
      final response = await _gateway.call(
        'api.delivery.get_delivery_points',
        requireAuth: false,
      );
      final List<dynamic> data = response;
      final List<DeliveryPointData> deliveryPoints =
          data.map((e) => DeliveryPointData.fromJson(e)).toList();
      return ApiResult.success(data: deliveryPoints);
    } catch (e) {
      debugPrint('==> get all delivery points failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}
