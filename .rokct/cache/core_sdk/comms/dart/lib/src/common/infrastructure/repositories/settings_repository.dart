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
import 'package:base_sdk/src/domain/interface/settings.dart';
import 'package:base_sdk/src/models/data/help_data.dart';
import 'package:base_sdk/src/models/data/notification_list_data.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/models/data/translation.dart';

class SettingsRepository implements SettingsRepositoryFacade {
  static const _gateway = PlatformGateway();

  @override
  Future<ApiResult<GlobalSettingsResponse>> getGlobalSettings() async {
    try {
      final data = await _gateway.call(
        'api.system.get_global_settings',
        requireAuth: false,
      );
      return ApiResult.success(
        data: GlobalSettingsResponse.fromJson(data),
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
      final response = await _gateway.call(
        'api.translation.get_mobile_translations',
        payload: data,
        requireAuth: false,
      );
      return ApiResult.success(
        data: MobileTranslationsResponse.fromJson(response),
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
      final data = await _gateway.call(
        'api.system.get_languages',
        requireAuth: false,
      );
      // A null stored id must never count as "found" (two missing ids used
      // to read as a match through contains(null)).
      final storedLanguageId = LocalStorage.getLanguage()?.id;
      if (storedLanguageId == null ||
          !(LanguagesResponse.fromJson(data)
                  .data
                  ?.map((e) => e.id)
                  .contains(storedLanguageId) ??
              true)) {
        LanguagesResponse.fromJson(data).data?.forEach((element) {
          if (element.isDefault ?? false) {
            LocalStorage.setLanguageData(element);
          }
        });
      }
      return ApiResult.success(data: LanguagesResponse.fromJson(data));
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
      final data = await _gateway.tenant('api.admin_content.get_admin_faqs');
      return ApiResult.success(data: HelpModel.fromJson(data));
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
      final data = await _gateway.call(
        'api.page.get_page',
        payload: {'slug': 'term'},
        requireAuth: false,
      );
      // Response structure adaptation needed. Assuming get_page returns the page doc.
      // Translation.fromJson expects map.
      return ApiResult.success(data: Translation.fromJson(data));
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
      final data = await _gateway.call(
        'api.page.get_page',
        payload: {'slug': 'policy'},
        requireAuth: false,
      );
      return ApiResult.success(data: Translation.fromJson(data));
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
      // Using parities with NotificationRepository or dedicated settings endpoint
      final data = await _gateway.tenant(
        'api.notification.get_notification_settings',
      );
      return ApiResult.success(
        data: notificationsListModelFromJson(data) ??
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
      // The backend's update_notification_settings(type, active) updates one
      // notification type per call and keys on `type`, not an id (settings
      // rows carry no usable id).
      for (final n in notifications ?? const <NotificationData>[]) {
        if (n.type == null) continue;
        await _gateway.tenant(
          'api.notification.update_notification_settings',
          {'type': n.type, 'active': (n.active ?? false) ? 1 : 0},
        );
      }
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> update notification settings failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}
