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
import 'package:orders_sdk/src/manager/domain/interface/shop_drivers.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/shop_driver.dart';

/// The shop's own-driver roster over the universal platform gateway.
///
/// The cmds follow the same fleet rule every repository in this slice
/// follows — the owning module's whitelist key with the app segment dropped
/// — so zones' `{app_name}.api.shop_drivers.<fn>` becomes
/// `api.shop_drivers.<fn>`, exactly as the load module's keys become
/// `api.order.load.<fn>` next door. Nothing is faked: against a tenant
/// composed without zones' delivery module these three cmds do not resolve
/// and each call fails through [ApiResult.failure], leaving the roster
/// screen on its error state rather than inventing a roster.
class ShopDriversRepository implements ShopDriversRepositoryFacade {
  static const _gateway = PlatformGateway();

  ApiResult<T> _fail<T>(Object e, String label) {
    debugPrint('==> $label failure: $e');
    return ApiResult.failure(
      error: AppHelpers.errorHandler(e),
      statusCode: NetworkExceptions.getDioStatus(e),
    );
  }

  /// The roster answers a bare list; the gateway's Frappe interceptor has
  /// already unwrapped `message` by the time a response lands here, but a
  /// host talking to an older shell may still see the envelope, so both are
  /// accepted — the same two-shape read [ShopLoadsRepository] does.
  static Object? _unwrap(dynamic response) {
    if (response is Map && response.containsKey('message')) {
      return response['message'];
    }
    return response;
  }

  @override
  Future<ApiResult<List<ShopDriver>>> listShopDrivers() async {
    try {
      final response = await _gateway.tenant(
        'api.shop_drivers.list_shop_drivers',
      );
      return ApiResult.success(
        data: <ShopDriver>[
          for (final row in (_unwrap(response) as List?) ?? const [])
            if (row is Map) ShopDriver.fromJson(row.cast<String, dynamic>()),
        ],
      );
    } catch (e) {
      return _fail(e, 'list shop drivers');
    }
  }

  @override
  Future<ApiResult<bool>> addShopDriver({required String deliveryman}) async {
    try {
      await _gateway.tenant('api.shop_drivers.add_shop_driver', {
        'deliveryman': deliveryman,
      });
      return ApiResult.success(data: true);
    } catch (e) {
      return _fail(e, 'add shop driver $deliveryman');
    }
  }

  @override
  Future<ApiResult<bool>> removeShopDriver({
    required String deliveryman,
  }) async {
    try {
      await _gateway.tenant('api.shop_drivers.remove_shop_driver', {
        'deliveryman': deliveryman,
      });
      return ApiResult.success(data: true);
    } catch (e) {
      return _fail(e, 'remove shop driver $deliveryman');
    }
  }
}
