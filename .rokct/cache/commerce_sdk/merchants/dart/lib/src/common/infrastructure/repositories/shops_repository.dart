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
import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/domain/interface/shops.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:base_sdk/src/models/data/filter_model.dart';

class ShopsRepository implements ShopsRepositoryFacade {
  /// Universal platform gateway (fleet rule 2026-08-15): cmds mirror the
  /// owning modules' `manifest.json` whitelisted-method keys with the app
  /// segment dropped (`api.shop.*`, plus cross-module `api.cart.join_order`,
  /// `api.delivery.check_delivery_zone`, `api.story.get_story`,
  /// `api.tag.get_tags`, `api.product.get_suggest_price`).
  static const _gateway = PlatformGateway();

  @override
  Future<ApiResult<ShopsPaginateResponse>> searchShops({
    required String text,
    String? categoryId,
  }) async {
    final params = {
      'search': text,
      if (categoryId != null) 'category_id': categoryId,
    };
    try {
      final response = await _gateway.call(
        'api.shop.search_shops',
        payload: params,
        requireAuth: false,
      );
      return ApiResult.success(
        data: ShopsPaginateResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> search shops failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<ShopsPaginateResponse>> getAllShops(
    int page, {
    String? categoryId,
    FilterModel? filterModel,
    bool? isOpen,
    bool? verify,
  }) async {
    final params = {
      'limit_start': (page - 1) * 10,
      'limit_page_length': 10,
      if (categoryId != null) 'category_id': categoryId,
      if (filterModel?.sort != null) 'order_by': filterModel!.sort,
      if (isOpen ?? false) 'open': 1,
      if (verify ?? false) 'verify': 1,
    };
    try {
      final response = await _gateway.call(
        'api.shop.get_shops',
        payload: params,
        requireAuth: false,
      );
      return ApiResult.success(
        data: ShopsPaginateResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> get all shops failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<SingleShopResponse>> getSingleShop({
    required String uuid,
  }) async {
    try {
      final client = dioHttp.client(requireAuth: false);
      final response = await client.get(
        '/api/method/paas.api.shop.shop.get_shop_by_uuid',
        queryParameters: {'uuid': uuid},
      );
      return ApiResult.success(
        data: SingleShopResponse.fromJson(response.data),
      );
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<bool>> checkDriverZone(
    LatLng location, {
    String? shopId,
  }) async {
    try {
      final data = {
        'latitude': location.latitude,
        'longitude': location.longitude,
        if (shopId != null) 'shop_id': shopId,
      };
      // zones delivery module owns check_delivery_zone.
      final response = await _gateway.call(
        'api.delivery.check_delivery_zone',
        payload: data,
        requireAuth: false,
      );
      return ApiResult.success(data: response["status"] == "success");
    } catch (e) {
      debugPrint('==> get delivery zone failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  // NOTE: The following methods are not supported by the new backend or have been consolidated.
  // - getNearbyShops
  // - getShopBranch
  // - joinOrder
  // - getShopFilter
  // - getPickupShops
  // - getShopsByIds
  // - createShop
  // - getShopsRecommend
  // - getStory
  // - getTags
  // - getSuggestPrice

  @override
  Future<ApiResult<ShopsPaginateResponse>> getNearbyShops(
    double latitude,
    double longitude,
  ) async {
    final params = {'latitude': latitude, 'longitude': longitude};
    try {
      final response = await _gateway.call(
        'api.shop.get_nearby_shops',
        payload: params,
        requireAuth: false,
      );
      return ApiResult.success(
        data: ShopsPaginateResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> get nearby shops failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<BranchResponse>> getShopBranch({
    required String uuid,
  }) async {
    try {
      final client = dioHttp.client(requireAuth: false);
      final response = await client.get(
        '/api/method/paas.api.shop.shop.get_shop_branch',
        queryParameters: {'shop_id': uuid},
      );
      return ApiResult.success(data: BranchResponse.fromJson(response.data));
    } catch (e) {
      debugPrint('==> get shop branch failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult> joinOrder({
    required String shopId,
    required String name,
    required String cartId,
  }) async {
    try {
      // Group-order join lives in orders' cart module (cart.join_order);
      // its kwargs are cart_id/user_name.
      await _gateway.tenant(
        'api.cart.join_order',
        {'cart_id': cartId, 'user_name': name, 'shop_id': shopId},
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> join order failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<ShopsPaginateResponse>> getShopFilter({
    String? categoryId,
    required int page,
    String? subCategoryId,
  }) async {
    return getAllShops(page, categoryId: categoryId);
  }

  @override
  Future<ApiResult<ShopsPaginateResponse>> getPickupShops() async {
    try {
      final client = dioHttp.client(requireAuth: false);
      final response = await client.get(
        '/api/method/paas.api.shop.shop.get_pickup_shops',
      );
      return ApiResult.success(
        data: ShopsPaginateResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get pickup shops failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<ShopsPaginateResponse>> getShopsByIds(
    List<String> shopIds,
  ) async {
    try {
      // Backend kwarg is shop_ids (shop.get_shops_by_ids); the old 'ids'
      // key was never read server-side.
      final response = await _gateway.call(
        'api.shop.get_shops_by_ids',
        payload: {'shop_ids': shopIds},
        requireAuth: false,
      );
      return ApiResult.success(
        data: ShopsPaginateResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> get shops by ids failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<void>> createShop({
    required double tax,
    required List<String> documents,
    required double deliveryTo,
    required double deliveryFrom,
    required String deliveryType,
    required String phone,
    required String name,
    required String category,
    required String description,
    required double startPrice,
    required double perKm,
    AddressNewModel? address,
    String? logoImage,
    String? backgroundImage,
  }) async {
    final data = {
      'tax': tax,
      'documents': documents,
      'delivery_to': deliveryTo,
      'delivery_from': deliveryFrom,
      'delivery_type': deliveryType,
      'phone': phone,
      'name': name,
      'category': category,
      'description': description,
      'start_price': startPrice,
      'per_km': perKm,
      if (address != null) 'address': address.toJson(),
      if (logoImage != null) 'logo': logoImage,
      if (backgroundImage != null) 'background': backgroundImage,
    };
    try {
      // Backend signature is create_shop(shop_data) — the fields ride inside
      // a single shop_data map.
      await _gateway.tenant('api.shop.create_shop', {'shop_data': data});
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> create shop failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<ShopsPaginateResponse>> getShopsRecommend(int page) async {
    try {
      // NOTE: backend get_shops_recommend(latitude, longitude) requires
      // coordinates this facade does not receive — recorded contract gap;
      // the call is at least routed to the real endpoint now.
      final response = await _gateway.call(
        'api.shop.get_shops_recommend',
        payload: {'page': page},
        requireAuth: false,
      );
      return ApiResult.success(
        data: ShopsPaginateResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> get recommended shops failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<List<List<StoryModel?>?>?>> getStory(int page) async {
    try {
      final response = await _gateway.call(
        'api.story.get_story',
        payload: {'page': page},
        requireAuth: false,
      );
      return ApiResult.success(
        data: storyModelFromJson(response['message']),
      );
    } catch (e) {
      debugPrint('==> get story failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<TagResponse>> getTags(String categoryId) async {
    try {
      // Tags live in products' tag module (tag.get_tags).
      final response = await _gateway.call(
        'api.tag.get_tags',
        payload: {'category_id': categoryId},
        requireAuth: false,
      );
      return ApiResult.success(data: TagResponse.fromJson(response));
    } catch (e) {
      debugPrint('==> get tags failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<PriceModel>> getSuggestPrice() async {
    try {
      // Suggested price lives in products' product module
      // (product.get_suggest_price).
      final response = await _gateway.call(
        'api.product.get_suggest_price',
        requireAuth: false,
      );
      return ApiResult.success(
        data: PriceModel.fromJson(response['message']),
      );
    } catch (e) {
      debugPrint('==> get suggest price failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}
