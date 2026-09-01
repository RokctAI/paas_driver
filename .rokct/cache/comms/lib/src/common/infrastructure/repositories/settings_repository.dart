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
      dynamic response;
      try {
        response = await _gateway.call(
          'api.translation.get_mobile_translations',
          payload: data,
          requireAuth: false,
        );
      } catch (_) {
        // The unprefixed cmd resolves only on tenant-role sites; a
        // control-role gateway rejects any cmd without the `control:`
        // prefix, and rejection shapes differ per role gateway — so
        // rather than pattern-matching the error, retry the fetch once
        // under the control-role key (the same deterministic fallback
        // TranslationSeeder uses for its seed push). The read is
        // side-effect free, so the extra attempt is harmless; if this
        // one fails too, the outer catch reports the failure as before.
        response = await _gateway.call(
          'control:get_mobile_translations',
          payload: data,
          requireAuth: false,
        );
      }
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
      // The picker's catalogue is the `PaaS Language` doctype, NOT
      // Frappe's stock `Language` list. `api.system.get_languages` serves
      // the latter and answers only `name`/`language_name`, so every row
      // parsed out of it carried a null `title` AND a null `locale` — and
      // because that parse SUCCEEDS, the failure never surfaced: the
      // picker drew blank rows and `getMobileTranslations` fell back to
      // `'en'` for every language. `api.language.get_languages` is the
      // endpoint shaped for LanguageData (title/locale/backward/default/
      // active/img) and is whitelisted allow_guest, so the pre-login
      // picker still reaches it.
      final data = await _gateway.call(
        'api.language.get_languages',
        requireAuth: false,
      );
      final languages = LanguagesResponse.fromJson(data);
      // A null stored id must never count as "found" (two missing ids used
      // to read as a match through contains(null)).
      final storedLanguageId = LocalStorage.getLanguage()?.id;
      if (storedLanguageId == null ||
          !(languages.data?.map((e) => e.id).contains(storedLanguageId) ??
              true)) {
        languages.data?.forEach((element) {
          if (element.isDefault ?? false) {
            LocalStorage.setLanguageData(element);
          }
        });
      }
      return ApiResult.success(data: languages);
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
