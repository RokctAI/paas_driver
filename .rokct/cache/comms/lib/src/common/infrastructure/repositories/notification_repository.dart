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
