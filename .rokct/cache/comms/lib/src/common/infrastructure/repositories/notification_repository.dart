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
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/handlers/network_exceptions.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/domain/interface/notification.dart';
import 'package:base_sdk/src/models/data/count_of_notifications_data.dart';
import 'package:base_sdk/src/models/response/notification_response.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

/// Calls `core/comms/frappe`'s notification module through base_sdk's
/// universal platform gateway ([PlatformGateway]). Cmd names mirror that
/// module's `manifest.json` whitelisted-method aliases with the
/// `{app_name}` segment dropped (`api.notification.*`).
class NotificationRepositoryImpl extends NotificationRepositoryFacade {
  static const _gateway = PlatformGateway();

  @override
  Future<ApiResult<NotificationResponse>> getNotifications({int? page}) async {
    final data = {'limit_start': ((page ?? 1) - 1) * 7, 'limit_page_length': 7};
    try {
      final response = await _gateway.tenant(
        'api.notification.get_user_notifications',
        data,
      );
      return ApiResult.success(
        data: NotificationResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> get notification failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<NotificationResponse>> readAll() async {
    try {
      await _gateway.tenant('api.notification.read_all_notifications');
      return ApiResult.success(data: NotificationResponse());
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<dynamic>> readOne({String? id}) async {
    try {
      await _gateway.tenant(
        'api.notification.read_one_notification',
        {'name': id},
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<CountNotificationModel>> getCount() async {
    try {
      final response = await _gateway.tenant(
        'api.notification.get_notification_count',
      );
      return ApiResult.success(
        data: CountNotificationModel.fromJson(
          response is Map ? (response['message'] ?? response) : response,
        ),
      );
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}
