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
import 'package:base_sdk/src/domain/interface/cart.dart';
import 'package:base_sdk/src/models/data/cart_data.dart';
import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/handlers/network_exceptions.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

import 'dart:convert';
import 'package:base_sdk/src/models/request/cart_request.dart';

class CartRepository implements CartRepositoryFacade {
  /// Universal platform gateway (fleet rule 2026-08-15): cart cmds are the
  /// orders module's `manifest.json` whitelisted-method keys with the app
  /// segment dropped (`api.cart.*`).
  static const _gateway = PlatformGateway();

  @override
  Future<ApiResult<CartModel>> getCart(String shopId) async {
    try {
      final response = await _gateway.tenant(
        'api.cart.get_cart',
        {'shop_id': shopId},
      );
      return ApiResult.success(data: CartModel.fromJson(response));
    } catch (e) {
      debugPrint('==> getCart failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  Future<ApiResult<CartModel>> addToCart({
    required String itemCode,
    required int qty,
    required String shopId,
  }) async {
    return insertCart(
      cart: CartRequest(productId: itemCode, quantity: qty, shopId: shopId),
    );
  }

  @override
  Future<ApiResult<CartModel>> getCartInGroup(
    String? cartId,
    String? shopId,
    String? cartUuid,
  ) async {
    final params = {
      if (cartId != null) 'cart_id': cartId,
      if (shopId != null) 'shop_id': shopId,
      if (cartUuid != null) 'cart_uuid': cartUuid,
    };
    try {
      final response = await _gateway.tenant('api.cart.get_cart_in_group', params);
      return ApiResult.success(data: CartModel.fromJson(response));
    } catch (e) {
      debugPrint('==> getCartInGroup failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<dynamic>> startGroupOrder({required String cartId}) async {
    // TODO(fix-wave 2026-09-02): no server method — the orders frappe half
    // whitelists get_cart_in_group / insert_cart_with_group / join_order only
    // (join_order is itself a placeholder). Left on the dead per-method path
    // so the failure stays visible; needs an owner decision (fixplan M11).
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/method/paas.api.start_group_order',
        data: {'cart_id': cartId},
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> startGroupOrder failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<dynamic>> changeStatus({
    required String? userUuid,
    required String? cartId,
  }) async {
    try {
      await _gateway.tenant(
        'api.cart.change_status',
        {'user_uuid': userUuid, 'cart_id': cartId},
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> changeStatus failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<CartModel>> deleteCart({required String cartId}) async {
    try {
      final response = await _gateway.tenant(
        'api.cart.delete_cart',
        {'cart_id': cartId},
      );
      return ApiResult.success(data: CartModel.fromJson(response));
    } catch (e) {
      debugPrint('==> deleteCart failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<dynamic>> deleteUser({
    required String cartId,
    required String userId,
  }) async {
    try {
      await _gateway.tenant(
        'api.cart.delete_user',
        {'cart_id': cartId, 'user_id': userId},
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> deleteUser failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<CartModel>> removeProductCart({
    required String cartDetailId,
    List<String>? listOfId,
  }) async {
    try {
      final response = await _gateway.tenant(
        'api.cart.remove_product_cart',
        {'cart_detail_id': cartDetailId},
      );
      return ApiResult.success(data: CartModel.fromJson(response));
    } catch (e) {
      debugPrint('==> removeProductCart failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<CartModel>> createAndCart({
    required CartRequest cart,
  }) async {
    return insertCart(cart: cart);
  }

  @override
  Future<ApiResult<CartModel>> insertCart({required CartRequest cart}) async {
    try {
      final params = cart.toJson();
      // Ensure specific keys are used for the add_to_cart endpoint if needed
      if (cart.productId != null) params['item_code'] = cart.productId;
      if (cart.quantity != null) params['qty'] = cart.quantity;

      if (cart.carts != null) {
        params['addons'] = jsonEncode(cart.toJsonCart());
      }
      final response = await _gateway.tenant('api.cart.add_to_cart', params);
      return ApiResult.success(data: CartModel.fromJson(response));
    } catch (e) {
      debugPrint('==> insertCart failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<CartModel>> insertCartWithGroup({
    required CartRequest cart,
  }) async {
    try {
      // orders' cart.insert_cart_with_group(cart, lang) — the cart body rides
      // inside a single `cart` kwarg (fixplan M10).
      final response = await _gateway.tenant(
        'api.cart.insert_cart_with_group',
        {'cart': cart.toJson()},
      );
      return ApiResult.success(data: CartModel.fromJson(response));
    } catch (e) {
      debugPrint('==> insertCartWithGroup failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<CartModel>> createCart({required CartRequest cart}) async {
    if (cart.shopId != null) {
      return getCart(cart.shopId!);
    }
    return ApiResult.failure(error: "Shop ID is required", statusCode: 400);
  }
}
