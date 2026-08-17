// Copyright (c) 2026 RokctAI
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
import 'package:base_sdk/src/domain/interface/blogs.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';

class BlogsRepository implements BlogsRepositoryFacade {
  /// Prefix-free cmd base for the universal platform gateway: the
  /// promotions module's `manifest.json` whitelisted-method keys
  /// (`{app_name}.api.blog.*`) with the app segment dropped.
  static const _cmd = 'api.blog';

  static const _gateway = PlatformGateway();

  @override
  Future<ApiResult<BlogsPaginateResponse>> getBlogs(
    int page,
    String type,
  ) async {
    final data = {
      'perPage': 15,
      'page': page,
      'type': type,
      'lang': LocalStorage.getLanguage()?.locale,
    };
    try {
      // Guest endpoint, through the universal platform gateway.
      final response = await _gateway.call(
        '$_cmd.get_blogs',
        payload: data,
        requireAuth: false,
      );
      return ApiResult.success(
        data: BlogsPaginateResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> get blogs paginate failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<BlogDetailsResponse>> getBlogDetails(String uuid) async {
    try {
      // Guest endpoint, through the universal platform gateway.
      final response = await _gateway.call(
        '$_cmd.get_blog',
        payload: {'uuid': uuid},
        requireAuth: false,
      );
      return ApiResult.success(
        data: BlogDetailsResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> get blogs details failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}
