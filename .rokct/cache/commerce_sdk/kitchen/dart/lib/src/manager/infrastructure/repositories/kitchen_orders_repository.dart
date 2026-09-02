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
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:kitchen_sdk/src/manager/domain/interface/kitchen_orders.dart';
import 'package:kitchen_sdk/src/manager/infrastructure/models/response/kitchen_orders_response.dart';
import 'package:kitchen_sdk/src/manager/presentation/kitchen/kitchen_status.dart';

/// Gateway-riding implementation (this SDK's KitchensRepository
/// precedent): every call is a universal-gateway cmd, so the same code
/// runs against whatever backend the composed app's baseUrl points at.
class KitchenOrdersRepository implements KitchenOrdersRepositoryFacade {
  static const _gateway = PlatformGateway();

  static const int _pageLength = 20;

  ApiResult<T> _fail<T>(Object e, String label) {
    debugPrint('==> $label failure: $e');
    return ApiResult.failure(
      error: AppHelpers.errorHandler(e),
      statusCode: NetworkExceptions.getDioStatus(e),
    );
  }

  @override
  Future<ApiResult<KitchenOrdersResponse>> getKitchenOrders({
    KitchenStatus? status,
    String? search,
    int? page,
  }) async {
    try {
      final response = await _gateway.tenant('api.cook.get_kitchen_orders', {
        if (status != null) 'status': status.wire,
        if (search != null && search.isNotEmpty) 'search': search,
        if (page != null) 'limit_start': (page - 1) * _pageLength,
        'limit_page_length': _pageLength,
        'lang': LocalStorage.getLanguage()?.locale,
      });
      return ApiResult.success(
        data: KitchenOrdersResponse.fromJson(response),
      );
    } catch (e) {
      return _fail(e, 'get kitchen orders ${status?.wire ?? 'all'}');
    }
  }

  @override
  Future<ApiResult<void>> updateOrderStatus({
    required String orderId,
    required String wireStatus,
  }) async {
    try {
      await _gateway.tenant('api.seller_order.update_seller_order_status', {
        'order_id': orderId,
        'status': wireStatus,
      });
      return const ApiResult.success(data: null);
    } catch (e) {
      return _fail(e, 'update kitchen order status $wireStatus');
    }
  }

  @override
  Future<ApiResult<void>> updateDishStatus({
    required String orderId,
    required String dishId,
    required DishStatus status,
  }) async {
    try {
      await _gateway.tenant('api.cook.update_kitchen_dish_status', {
        'order_id': orderId,
        'item_id': dishId,
        'prep_status': status.wire,
      });
      return const ApiResult.success(data: null);
    } catch (e) {
      return _fail(e, 'update kitchen dish status ${status.wire}');
    }
  }
}
