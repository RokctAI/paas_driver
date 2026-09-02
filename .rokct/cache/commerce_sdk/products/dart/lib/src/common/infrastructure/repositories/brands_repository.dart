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
