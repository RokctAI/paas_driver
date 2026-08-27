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
import 'package:base_sdk/src/domain/interface/brands.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/local_storage.dart';

class BrandsRepository implements BrandsRepositoryFacade {
  /// Universal platform gateway (fleet rule 2026-08-15): brand cmds are the
  /// products module's `manifest.json` whitelisted-method keys with the app
  /// segment dropped (`api.brand.*`).
  static const _gateway = PlatformGateway();

  @override
  Future<ApiResult<BrandsPaginateResponse>> getBrandsPaginate(
    int page, {
    int? pageSize,
    String? search,
  }) async {
    final params = {
      'limit_start': (page - 1) * (pageSize ?? 18),
      'limit_page_length': pageSize ?? 18,
      'lang': LocalStorage.getLanguage()?.locale,
      if (search != null) 'search': search,
    };
    try {
      final response = await _gateway.call(
        'api.brand.get_brands',
        payload: params,
        requireAuth: false,
      );
      return ApiResult.success(
        data: BrandsPaginateResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> get brands paginate failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<SingleBrandResponse>> getSingleBrand(String uuid) async {
    try {
      final response = await _gateway.call(
        'api.brand.get_brand_by_uuid',
        payload: {
          'uuid': uuid,
          'lang': LocalStorage.getLanguage()?.locale,
        },
        requireAuth: false,
      );
      return ApiResult.success(
        data: SingleBrandResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> get brand failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<BrandsPaginateResponse>> getAllBrands({
    String? categoryId,
    String? shopId,
  }) {
    return getBrandsPaginate(1);
  }

  @override
  Future<ApiResult<BrandsPaginateResponse>> searchBrands(String query) {
    return getBrandsPaginate(1, search: query);
  }
}
