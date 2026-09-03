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
import 'package:orders_sdk/src/manager/domain/interface/pos_products.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/response/categories_paginate_response.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/response/products_paginate_response.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/response/single_product_response.dart';

/// The POS product-grid reads, repointed to the same `seller_product.py`
/// endpoints products_sdk's authoring repositories call (their payload
/// contract is copied from `seller_products_repository.dart` so the two stay
/// wire-compatible), through the universal gateway as merchants'
/// `api.seller_product.*` cmds. Read-only: everything that writes products
/// stays in products_sdk.
class PosProductsRepository implements PosProductsRepositoryFacade {
  /// Universal platform gateway (fleet rule 2026-08-15): cmds mirror the
  /// merchants module's `manifest.json` whitelisted-method keys with the app
  /// segment dropped.
  static const _gateway = PlatformGateway();

  /// Mirrors the backend's `limit_page_length` default; the legacy `page`
  /// query becomes `limit_start`.
  static const int _pageSize = 20;

  ApiResult<T> _fail<T>(Object e, String label) {
    debugPrint('==> $label failure: $e');
    return ApiResult.failure(
      error: AppHelpers.errorHandler(e),
      statusCode: NetworkExceptions.getDioStatus(e),
    );
  }

  @override
  Future<ApiResult<ProductsPaginateResponse>> getProducts({
    bool active = true,
    int? page,
    String? categoryId,
    String? query,
    String? status,
  }) async {
    try {
      final response = await _gateway.tenant(
        'api.seller_product.get_seller_products',
        {
          'lang': LocalStorage.getLanguage()?.locale,
          if (page != null) 'limit_start': (page - 1) * _pageSize,
          'limit_page_length': _pageSize,
          if (query != null && query.isNotEmpty) 'search': query,
          if (categoryId != null) 'category_id': categoryId,
          if (status != null) 'status': status,
          if (active) 'active': 1,
        },
      );
      return ApiResult.success(
        data: ProductsPaginateResponse.fromJson(response),
      );
    } catch (e) {
      return _fail(e, 'pos get products');
    }
  }

  @override
  Future<ApiResult<CategoriesPaginateResponse>> getShopCategories({
    int? page,
  }) async {
    try {
      final response = await _gateway.tenant(
        'api.seller_product.get_seller_categories',
        {
          'lang': LocalStorage.getLanguage()?.locale,
          if (page != null) 'limit_start': (page - 1) * _pageSize,
          'limit_page_length': _pageSize,
          'type': 'main',
        },
      );
      return ApiResult.success(
        data: CategoriesPaginateResponse.fromJson(response),
      );
    } catch (e) {
      return _fail(e, 'pos get shop categories');
    }
  }

  @override
  Future<ApiResult<SingleProductResponse>> getProductDetails(
    String uuid,
  ) async {
    try {
      // seller_product.get_product_details(product_name): the POS grid's
      // `uuid` is the Product docname.
      final response = await _gateway.tenant(
        'api.seller_product.get_product_details',
        {
          'product_name': uuid,
          'lang': LocalStorage.getLanguage()?.locale,
        },
      );
      return ApiResult.success(
        data: SingleProductResponse.fromJson(response),
      );
    } catch (e) {
      return _fail(e, 'pos get product details');
    }
  }
}
