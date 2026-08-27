// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
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
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:products_sdk/src/common/domain/interface/seller_catalog.dart';
import 'package:products_sdk/src/common/infrastructure/models/response/seller_categories_paginate_response.dart';
import 'package:products_sdk/src/common/infrastructure/models/response/seller_units_paginate_response.dart';

/// Port of `paas_manager`'s `catalog_repository`, repointed from
/// `/api/v1/dashboard/seller/{units,categories}` to `seller_product.py`.
///
/// `getKitchens` is deliberately absent: kitchens moved to `kitchen_sdk`, and
/// ADR-005 forbids this package importing it.
const _base = '/api/method/paas.api.seller_product.seller_product';

class SellerCatalogRepository implements SellerCatalogRepositoryFacade {
  @override
  Future<ApiResult<SellerUnitsPaginateResponse>> getUnits() async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '$_base.get_seller_units',
        queryParameters: {
          'lang': LocalStorage.getLanguage()?.locale,
          'limit_page_length': 100,
        },
      );
      return ApiResult.success(
        data: SellerUnitsPaginateResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get seller units failure: $e');
      return _fail(e);
    }
  }

  @override
  Future<ApiResult<SellerCategoriesPaginateResponse>> getCategories({
    int? page,
    String? query,
  }) =>
      _categories(page: page, query: query, type: 'main', activeOnly: true);

  @override
  Future<ApiResult<SellerCategoriesPaginateResponse>> getShopCategories({
    int? page,
    String? query,
  }) =>
      _categories(page: page, query: query, type: 'main', activeOnly: false);

  @override
  Future<ApiResult<SellerCategoriesPaginateResponse>> getCategoriesSub({
    int? page,
    String? query,
  }) =>
      _categories(page: page, query: query, type: 'sub_shop', activeOnly: true);

  @override
  Future<ApiResult<void>> createCategory({
    required String title,
    required String input,
  }) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '$_base.create_seller_category',
        data: {
          // The legacy client posted a locale-keyed title map; kept, since the
          // category doctype is translatable the same way.
          //
          // It keyed this on `LocalStorage.getSystemLanguage()` — the shop's
          // default authoring locale, distinct from the UI display language.
          // base_sdk's LocalStorage has no system-language accessor (only
          // `getLanguage()`), and widening base_sdk is not this fork's call, so
          // the display locale is used. Consequence: a seller running the app
          // in a non-default language files a new category's title under that
          // language instead of the shop default. Worth a base_sdk accessor if
          // that matters.
          'title': {LocalStorage.getLanguage()?.locale ?? 'en': title},
          'active': 1,
          'input': input,
          'type': 'main',
        },
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> create seller category failure: $e');
      return _fail(e);
    }
  }

  @override
  Future<ApiResult<void>> deleteCategory({required String id}) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '$_base.delete_seller_category',
        // The endpoint resolves the category by its `uuid` argument.
        data: {'uuid': id},
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> delete seller category failure: $e');
      return _fail(e);
    }
  }

  Future<ApiResult<SellerCategoriesPaginateResponse>> _categories({
    int? page,
    String? query,
    required String type,
    required bool activeOnly,
  }) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '$_base.get_seller_categories',
        queryParameters: {
          if (page != null) 'page': page,
          if (query != null && query.isNotEmpty) 'search': query,
          'lang': LocalStorage.getLanguage()?.locale,
          'type': type,
          if (activeOnly) 'active': 1,
        },
      );
      return ApiResult.success(
        data: SellerCategoriesPaginateResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get seller categories failure: $e');
      return _fail(e);
    }
  }

  ApiResult<T> _fail<T>(Object e) => ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
}
