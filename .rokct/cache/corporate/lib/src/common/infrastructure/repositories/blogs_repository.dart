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
import 'package:base_sdk/src/domain/interface/blogs.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';

class BlogsRepository implements BlogsRepositoryFacade {
  /// Prefix-free cmd base for the universal platform gateway: the
  /// promotions module's `manifest.json` whitelisted-method keys
  /// (`{app_name}.api.blog.*`, targets in base's `tenant/api/blog/blog.py`)
  /// with the app segment dropped.
  static const _cmd = 'api.blog';

  static const _gateway = PlatformGateway();

  /// The Frappe `Blog` doctype has no `uuid` field: `api.blog.get_blogs`
  /// answers rows keyed by the DOCNAME (`name`, alongside `title`,
  /// `short_description`, `img`, `published_at`, `author`, `type`) and
  /// `api.blog.get_blog` answers `frappe.get_doc("Blog", name).as_dict()`.
  /// base_sdk's `BlogData.fromJson` still reads the pre-fork Laravel key
  /// `uuid`, so without this mirror every list row carried a null `uuid`
  /// and [getBlogDetails] was handed nothing to send. `name` is copied into
  /// `uuid` on each row (list) or the single `data` map (details); rows
  /// that already carry a `uuid` are left alone, and any other shape is
  /// passed through untouched. Pure, so the payload test pins it.
  static dynamic withBlogDocnames(dynamic response) {
    if (response is! Map) return response;
    final data = response['data'];
    if (data is List) {
      return <String, dynamic>{
        ...Map<String, dynamic>.from(response),
        'data': data.map(_mirrorDocname).toList(),
      };
    }
    if (data is Map) {
      return <String, dynamic>{
        ...Map<String, dynamic>.from(response),
        'data': _mirrorDocname(data),
      };
    }
    return response;
  }

  static dynamic _mirrorDocname(dynamic row) {
    if (row is Map && row['uuid'] == null && row['name'] != null) {
      return <String, dynamic>{
        ...Map<String, dynamic>.from(row),
        'uuid': row['name'],
      };
    }
    return row;
  }

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
        data: BlogsPaginateResponse.fromJson(withBlogDocnames(response)),
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
      // Guest endpoint, through the universal platform gateway. The server
      // signature is `get_blog(name)` (base `blog.py`, an alias of
      // `get_blog_details`): the value is the Blog DOCNAME, which the list
      // rows carry as `uuid` only because [withBlogDocnames] mirrored it
      // there. The facade keeps its `uuid` parameter name for callers.
      final response = await _gateway.call(
        '$_cmd.get_blog',
        payload: {'name': uuid},
        requireAuth: false,
      );
      return ApiResult.success(
        data: BlogDetailsResponse.fromJson(withBlogDocnames(response)),
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
