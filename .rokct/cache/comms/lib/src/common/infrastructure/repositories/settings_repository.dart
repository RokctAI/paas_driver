import 'package:flutter/material.dart';
import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/domain/interface/settings.dart';
import 'package:base_sdk/src/models/data/help_data.dart';
import 'package:base_sdk/src/models/data/notification_list_data.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/models/data/translation.dart';

class SettingsRepository implements SettingsRepositoryFacade {
  @override
  Future<ApiResult<GlobalSettingsResponse>> getGlobalSettings() async {
    try {
      final client = dioHttp.client(requireAuth: false);
      final response = await client.get(
        '/api/method/paas.api.system.system.get_global_settings',
      );
      return ApiResult.success(
        data: GlobalSettingsResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get settings failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<MobileTranslationsResponse>> getMobileTranslations() async {
    final data = {'lang': LocalStorage.getLanguage()?.locale ?? 'en'};
    try {
      final client = dioHttp.client(requireAuth: false);
      final response = await client.get(
        '/api/method/paas.api.translation.get_mobile_translations',
        queryParameters: data,
      );
      return ApiResult.success(
        data: MobileTranslationsResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get translations failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<LanguagesResponse>> getLanguages() async {
    try {
      final client = dioHttp.client(requireAuth: false);
      final response = await client.get(
        '/api/method/paas.api.system.system.get_languages',
      );
      if (LocalStorage.getLanguage() == null ||
          !(LanguagesResponse.fromJson(response.data)
                  .data
                  ?.map((e) => e.id)
                  .contains(LocalStorage.getLanguage()?.id) ??
              true)) {
        LanguagesResponse.fromJson(response.data).data?.forEach((element) {
          if (element.isDefault ?? false) {
            LocalStorage.setLanguageData(element);
          }
        });
      }
      return ApiResult.success(data: LanguagesResponse.fromJson(response.data));
    } catch (e) {
      debugPrint('==> get languages failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<HelpModel>> getFaq() async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/method/paas.api.admin_content.admin_content.get_admin_faqs',
      );
      return ApiResult.success(data: HelpModel.fromJson(response.data));
    } catch (e) {
      debugPrint('==> get faq failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<Translation>> getTerm() async {
    try {
      final client = dioHttp.client(requireAuth: false);
      final response = await client.get(
        '/api/method/paas.api.page.page.get_page',
        queryParameters: {'slug': 'term'},
      );
      // Response structure adaptation needed. Assuming get_page returns the page doc.
      // Translation.fromJson expects map.
      return ApiResult.success(data: Translation.fromJson(response.data));
    } catch (e) {
      debugPrint('==> get term failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<Translation>> getPolicy() async {
    try {
      final client = dioHttp.client(requireAuth: false);
      final response = await client.get(
        '/api/method/paas.api.page.page.get_page',
        queryParameters: {'slug': 'policy'},
      );
      return ApiResult.success(data: Translation.fromJson(response.data));
    } catch (e) {
      debugPrint('==> get policy failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<NotificationsListModel>> getNotificationList() async {
    try {
      final client = dioHttp.client(requireAuth: true);
      // Using parities with NotificationRepository or dedicated settings endpoint
      final response = await client.get(
        '/api/method/paas.api.notification.notification.get_notification_settings',
      );
      return ApiResult.success(
        data: notificationsListModelFromJson(response.data) ??
            NotificationsListModel(),
      );
    } catch (e) {
      debugPrint('==> get notification settings failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult> updateNotification(
    List<NotificationData>? notifications,
  ) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final data = {
        'notifications': notifications
            ?.map((n) => {'notification_id': n.id, 'active': n.active})
            .toList(),
      };
      await client.post(
        '/api/method/paas.api.notification.notification.update_notification_settings',
        data: data,
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> get languages failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}
