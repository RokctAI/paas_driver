import 'package:flutter/material.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/domain/interface/cart.dart';
import 'package:base_sdk/src/models/data/cart_data.dart';
import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/handlers/network_exceptions.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

import 'dart:convert';
import 'package:base_sdk/src/models/request/cart_request.dart';

class CartRepository implements CartRepositoryFacade {
  @override
  Future<ApiResult<CartModel>> getCart(String shopId) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/method/paas.api.cart.cart.get_cart',
        queryParameters: {'shop_id': shopId},
      );
      return ApiResult.success(data: CartModel.fromJson(response.data));
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
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/method/paas.api.get_cart_in_group',
        queryParameters: params,
      );
      return ApiResult.success(data: CartModel.fromJson(response.data));
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
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/method/paas.api.change_status',
        data: {'user_uuid': userUuid, 'cart_id': cartId},
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
      final client = dioHttp.client(requireAuth: true);
      final response = await client.post(
        '/api/method/paas.api.delete_cart',
        data: {'cart_id': cartId},
      );
      return ApiResult.success(data: CartModel.fromJson(response.data));
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
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/method/paas.api.delete_user',
        data: {'cart_id': cartId, 'user_id': userId},
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
      final client = dioHttp.client(requireAuth: true);
      final response = await client.post(
        '/api/method/paas.api.cart.cart.remove_product_cart',
        data: {'cart_detail_id': cartDetailId},
      );
      return ApiResult.success(data: CartModel.fromJson(response.data));
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
      final client = dioHttp.client(requireAuth: true);
      final params = cart.toJson();
      // Ensure specific keys are used for the add_to_cart endpoint if needed
      if (cart.productId != null) params['item_code'] = cart.productId;
      if (cart.quantity != null) params['qty'] = cart.quantity;

      if (cart.carts != null) {
        params['addons'] = jsonEncode(cart.toJsonCart());
      }
      final response = await client.post(
        '/api/method/paas.api.cart.cart.add_to_cart',
        data: params,
      );
      return ApiResult.success(data: CartModel.fromJson(response.data));
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
      final client = dioHttp.client(requireAuth: true);
      final response = await client.post(
        '/api/method/paas.api.add_to_cart_group',
        data: cart.toJson(),
      );
      return ApiResult.success(data: CartModel.fromJson(response.data));
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
