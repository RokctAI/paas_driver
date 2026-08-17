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

import 'package:flutter/material.dart';
import 'package:base_sdk/src/di/injection.dart';
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
      final client = dioHttp.client(requireAuth: false);
      final response = await client.get(
        '/api/method/paas.doctype.delivery_point.delivery_point.get_nearest_delivery_points',
        queryParameters: {'latitude': latitude, 'longitude': longitude},
      );
      final List<dynamic> data = response.data['message'];
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
