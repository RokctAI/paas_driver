import 'package:flutter/material.dart';
import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/handlers/network_exceptions.dart';
import 'package:base_sdk/src/domain/interface/notification.dart';
import 'package:base_sdk/src/models/data/count_of_notifications_data.dart';
import 'package:base_sdk/src/models/response/notification_response.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

class NotificationRepositoryImpl extends NotificationRepositoryFacade {
  @override
  Future<ApiResult<NotificationResponse>> getNotifications({int? page}) async {
    final data = {'limit_start': ((page ?? 1) - 1) * 7, 'limit_page_length': 7};
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/method/paas.api.user.user.get_user_notifications',
        queryParameters: data,
      );
      return ApiResult.success(
        data: NotificationResponse.fromJson(response.data),
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
      final client = dioHttp.client(requireAuth: true);
      await client.post('/api/method/paas.api.read_all_notifications');
      return ApiResult.success(data: NotificationResponse());
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<dynamic>> readOne({int? id}) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/method/paas.api.read_one_notification',
        data: {'notification_id': id},
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
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/method/paas.api.get_notification_count',
      );
      return ApiResult.success(
        data: CountNotificationModel.fromJson(response.data['message']),
      );
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}
