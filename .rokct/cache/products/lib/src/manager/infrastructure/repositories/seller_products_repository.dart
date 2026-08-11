import 'package:flutter/material.dart';
import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/common/infrastructure/models/response/create_seller_extras_response.dart';
import 'package:products_sdk/src/common/infrastructure/models/response/seller_extras_groups_response.dart';
import 'package:products_sdk/src/common/infrastructure/models/response/seller_group_extras_response.dart';
import 'package:products_sdk/src/common/infrastructure/models/response/seller_products_paginate_response.dart';
import 'package:products_sdk/src/common/infrastructure/models/response/single_seller_extras_group_response.dart';
import 'package:products_sdk/src/common/infrastructure/models/response/single_seller_product_response.dart';

/// Port of `paas_manager`'s product-authoring calls, repointed from the legacy
/// `/api/v1/dashboard/seller/...` paths to `seller_product.py` in the merchants
/// Frappe app. The Dart was already complete; only the server answering the URL
/// differs.
const _base = '/api/method/paas.api.seller_product.seller_product';

class SellerProductsRepository implements SellerProductsRepositoryFacade {
  @override
  Future<ApiResult<SellerProductsPaginateResponse>> getProducts({
    int? page,
    String? query,
    int? categoryId,
    bool needAddons = false,
    String? status,
  }) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '$_base.get_seller_products_paginate',
        queryParameters: {
          'lang': LocalStorage.getLanguage()?.locale,
          if (page != null) 'page': page,
          if (query != null && query.isNotEmpty) 'search': query,
          if (categoryId != null) 'category_id': categoryId,
          if (needAddons) 'addon': 1,
          if (status != null) 'status': status,
        },
      );
      return ApiResult.success(
        data: SellerProductsPaginateResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get seller products failure: $e');
      return _fail(e);
    }
  }

  @override
  Future<ApiResult<SingleSellerProductResponse>> getProductDetails(
    String uuid,
  ) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '$_base.get_product_details',
        queryParameters: {
          'uuid': uuid,
          'lang': LocalStorage.getLanguage()?.locale,
        },
      );
      return ApiResult.success(
        data: SingleSellerProductResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get seller product details failure: $e');
      return _fail(e);
    }
  }

  @override
  Future<ApiResult<SingleSellerProductResponse>> createProduct({
    required Map<String, dynamic> product,
  }) =>
      _postProduct('$_base.create_product', product);

  @override
  Future<ApiResult<SingleSellerProductResponse>> updateProduct({
    required String uuid,
    required Map<String, dynamic> product,
  }) =>
      _postProduct('$_base.update_seller_product', {'uuid': uuid, ...product});

  @override
  Future<ApiResult<SingleSellerProductResponse>> updateStocks({
    required String uuid,
    required List<Map<String, dynamic>> stocks,
    List<int> deletedStockIds = const [],
    bool isAddon = false,
  }) =>
      _postProduct('$_base.update_product_stocks', {
        'uuid': uuid,
        'stocks': stocks,
        if (deletedStockIds.isNotEmpty) 'delete_ids': deletedStockIds,
        if (isAddon) 'addon': 1,
      });

  @override
  Future<ApiResult<SingleSellerProductResponse>> updateExtras({
    required String productUuid,
    required List<Map<String, dynamic>> extras,
  }) =>
      _postProduct('$_base.update_product_extras', {
        'uuid': productUuid,
        'extras': extras,
      });

  @override
  Future<ApiResult<SellerExtrasGroupsResponse>> getExtrasGroups({
    int? page,
    bool needOnlyValid = true,
  }) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '$_base.get_extras_groups',
        queryParameters: {
          'lang': LocalStorage.getLanguage()?.locale,
          if (page != null) 'page': page,
          if (needOnlyValid) 'valid': true,
        },
      );
      return ApiResult.success(
        data: SellerExtrasGroupsResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get extras groups failure: $e');
      return _fail(e);
    }
  }

  @override
  Future<ApiResult<SellerGroupExtrasResponse>> getExtras({int? groupId}) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '$_base.get_seller_extra_values',
        queryParameters: {
          'group_id': groupId,
          'lang': LocalStorage.getLanguage()?.locale,
        },
      );
      return ApiResult.success(
        data: SellerGroupExtrasResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get extras failure: $e');
      return _fail(e);
    }
  }

  @override
  Future<ApiResult<SingleSellerExtrasGroupResponse>> createExtrasGroup({
    required Map<String, dynamic> group,
  }) =>
      _postGroup('$_base.create_extras_group', group);

  @override
  Future<ApiResult<SingleSellerExtrasGroupResponse>> updateExtrasGroup({
    required int groupId,
    required Map<String, dynamic> group,
  }) =>
      _postGroup('$_base.update_seller_extra_group', {
        'group_id': groupId,
        ...group,
      });

  @override
  Future<ApiResult<void>> deleteExtrasGroup({int? groupId}) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '$_base.delete_extras_group',
        data: {'group_id': groupId},
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> delete extras group failure: $e');
      return _fail(e);
    }
  }

  @override
  Future<ApiResult<CreateSellerExtrasResponse>> createExtrasItem({
    required Map<String, dynamic> item,
  }) =>
      _postExtrasValue('$_base.create_extras_value', item);

  @override
  Future<ApiResult<CreateSellerExtrasResponse>> updateExtrasItem({
    required int extrasId,
    required Map<String, dynamic> item,
  }) =>
      _postExtrasValue('$_base.update_seller_extra_value', {
        'extra_id': extrasId,
        ...item,
      });

  @override
  Future<ApiResult<void>> deleteExtrasItem({required List<int> ids}) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post('$_base.delete_extras_value', data: {'ids': ids});
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> delete extras item failure: $e');
      return _fail(e);
    }
  }

  Future<ApiResult<SingleSellerProductResponse>> _postProduct(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.post(path, data: body);
      return ApiResult.success(
        data: SingleSellerProductResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> $path failure: $e');
      return _fail(e);
    }
  }

  Future<ApiResult<SingleSellerExtrasGroupResponse>> _postGroup(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.post(path, data: body);
      return ApiResult.success(
        data: SingleSellerExtrasGroupResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> $path failure: $e');
      return _fail(e);
    }
  }

  Future<ApiResult<CreateSellerExtrasResponse>> _postExtrasValue(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.post(path, data: body);
      return ApiResult.success(
        data: CreateSellerExtrasResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> $path failure: $e');
      return _fail(e);
    }
  }

  ApiResult<T> _fail<T>(Object e) => ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
}
