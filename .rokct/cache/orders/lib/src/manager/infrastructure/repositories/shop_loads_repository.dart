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
import 'package:orders_sdk/src/manager/domain/interface/shop_loads.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/load_data.dart';

/// The shop half of `load.py` over the universal platform gateway.
///
/// The cmds mirror the owning module's `manifest.json` whitelist key with
/// the app segment dropped, the fleet rule every repository in this slice
/// follows — here `{app_name}.api.order.load.<fn>` becomes
/// `api.order.load.<fn>`, the same way the walk-in customer create reaches
/// `api.order.create_walk_in_customer`. Nothing is faked: a call the
/// backend cannot answer fails through [ApiResult.failure].
class ShopLoadsRepository implements ShopLoadsRepositoryFacade {
  static const _gateway = PlatformGateway();

  ApiResult<T> _fail<T>(Object e, String label) {
    debugPrint('==> $label failure: $e');
    return ApiResult.failure(
      error: AppHelpers.errorHandler(e),
      statusCode: NetworkExceptions.getDioStatus(e),
    );
  }

  /// `load.py` answers bare lists and bare objects; the gateway's Frappe
  /// interceptor has already unwrapped `message` by the time a response
  /// lands here, but a host talking to an older shell may still see the
  /// envelope, so both are accepted.
  static Object? _unwrap(dynamic response) {
    if (response is Map && response.containsKey('message')) {
      return response['message'];
    }
    return response;
  }

  static List<LoadData> _loads(dynamic response) => <LoadData>[
    for (final row in (_unwrap(response) as List?) ?? const [])
      if (row is Map) LoadData.fromJson(row.cast<String, dynamic>()),
  ];

  static LoadData _load(dynamic response) {
    final Object? payload = _unwrap(response);
    if (payload is! Map) {
      throw Exception('The load endpoint answered no load.');
    }
    return LoadData.fromJson(payload.cast<String, dynamic>());
  }

  @override
  Future<ApiResult<List<LoadData>>> getShopLoads({String? status}) async {
    try {
      final response = await _gateway.tenant('api.order.load.get_shop_loads', {
        if (status != null && status.isNotEmpty) 'status': status,
      });
      return ApiResult.success(data: _loads(response));
    } catch (e) {
      return _fail(e, 'get shop loads $status');
    }
  }

  @override
  Future<ApiResult<List<LoadDeliveryman>>> listShopDeliverymen() async {
    try {
      final response = await _gateway.tenant(
        'api.order.load.list_shop_deliverymen',
      );
      return ApiResult.success(
        data: <LoadDeliveryman>[
          for (final row in (_unwrap(response) as List?) ?? const [])
            if (row is Map)
              LoadDeliveryman.fromJson(row.cast<String, dynamic>()),
        ],
      );
    } catch (e) {
      return _fail(e, 'list shop deliverymen');
    }
  }

  @override
  Future<ApiResult<LoadData>> createLoad({
    required String deliveryman,
    required List<LoadIssueLine> items,
  }) async {
    try {
      final response = await _gateway.tenant('api.order.load.create_load', {
        'deliveryman': deliveryman,
        'items': [for (final item in items) item.toJson()],
      });
      return ApiResult.success(data: _load(response));
    } catch (e) {
      return _fail(e, 'create load for $deliveryman');
    }
  }

  @override
  Future<ApiResult<LoadData>> closeLoad({required String loadOrder}) async {
    try {
      final response = await _gateway.tenant('api.order.load.close_load', {
        'load_order': loadOrder,
      });
      return ApiResult.success(data: _load(response));
    } catch (e) {
      return _fail(e, 'close load $loadOrder');
    }
  }
}
