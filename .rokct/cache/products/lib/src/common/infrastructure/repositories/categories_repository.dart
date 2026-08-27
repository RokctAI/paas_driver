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

import 'package:base_sdk/src/domain/interface/categories.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

class CategoriesRepository implements CategoriesRepositoryFacade {
  /// Universal platform gateway (fleet rule 2026-08-15): category cmds are
  /// the products module's `manifest.json` whitelisted-method keys with the
  /// app segment dropped (`api.category.*`).
  static const _gateway = PlatformGateway();

  @override
  Future<ApiResult<CategoriesPaginateResponse>> getAllCategories({
    required int page,
    String? shopId,
  }) async {
    final params = {
      'limit_start': (page - 1) * 10,
      'limit_page_length': 10,
      if (shopId != null) 'shop_id': shopId,
    };

    try {
      final response = await _gateway.call(
        'api.category.get_categories',
        payload: params,
        requireAuth: false,
      );
      return ApiResult.success(
        data: CategoriesPaginateResponse.fromJson(response),
      );
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<CategoriesPaginateResponse>> searchCategories({
    required String text,
  }) async {
    final params = {'search': text};
    try {
      final response = await _gateway.call(
        'api.category.search_categories',
        payload: params,
        requireAuth: false,
      );
      return ApiResult.success(
        data: CategoriesPaginateResponse.fromJson(response),
      );
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<CategoriesPaginateResponse>> getCategoriesByShop({
    required String shopId,
  }) async {
    return getAllCategories(page: 1, shopId: shopId);
  }
}
