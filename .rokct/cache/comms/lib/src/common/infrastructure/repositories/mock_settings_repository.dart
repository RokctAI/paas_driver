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


import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/domain/interface/settings.dart';
import 'package:base_sdk/src/models/data/help_data.dart';
import 'package:base_sdk/src/models/data/notification_list_data.dart';
import 'package:base_sdk/src/models/data/translation.dart';
import 'package:base_sdk/src/models/response/global_settings_response.dart';
import 'package:base_sdk/src/models/response/languages_response.dart';
import 'package:base_sdk/src/models/response/mobile_translations_response.dart';

class MockSettingsRepository implements SettingsRepositoryFacade {
  @override
  Future<ApiResult<HelpModel>> getFaq() async {
    return ApiResult.success(
      data: HelpModel(
        data: [
          Datum(
            id: 1,
            translation: HelpTranslation(
              question: "How to order?",
              answer: "Select items and checkout",
              locale: "en",
            ),
          ),
        ],
      ),
    );
  }

  @override
  Future<ApiResult<GlobalSettingsResponse>> getGlobalSettings() async {
    return ApiResult.success(
      data: GlobalSettingsResponse(
        data: [
          SettingsData(key: "app_name", value: "Juvo Demo"),
          // The composed app's own brand name (AppHelpers.getAppName reads
          // the 'title' setting). AppConstants.appTitle is re-pointed per
          // app at compose time via the home SDK manifest's "constants"
          // overrides, so each demo build shows its own name instead of a
          // value shared by every composed app.
          SettingsData(key: "title", value: AppConstants.appTitle),
          SettingsData(key: "default_currency", value: "USD"),
          SettingsData(key: "default_tax", value: "10"),
          SettingsData(key: "deliveryman_order_acceptance_time", value: "30"),
          SettingsData(key: "google_maps_key", value: "DEMO_KEY"),
        ],
      ),
    );
  }

  @override
  Future<ApiResult<LanguagesResponse>> getLanguages() async {
    return ApiResult.success(
      data: LanguagesResponse(
        data: [
          LanguageData(
            id: "en",
            title: "English",
            backward: false,
            isDefault: true,
            locale: "en",
          ),
        ],
      ),
    );
  }

  @override
  Future<ApiResult<MobileTranslationsResponse>> getMobileTranslations() async {
    return ApiResult.success(
      data: MobileTranslationsResponse(
        data: {
          "home": "Home",
          "cart": "Cart",
          "profile": "Profile",
          // Brand motto shown on the onboarding welcome screen
          // (TrKeys.appMotto). Sourced from AppConstants.appMotto, which
          // each app's home SDK manifest re-points at its own brand
          // constants at compose time (default: the canonical JUVO motto
          // per brand docs). Production builds receive the motto from the
          // server-side translations instead.
          "motto": AppConstants.appMotto,
        },
      ),
    );
  }

  @override
  Future<ApiResult<NotificationsListModel>> getNotificationList() async {
    return ApiResult.success(
      data: NotificationsListModel(
        data: [
          NotificationData(
            id: "order",
            type: "order",
            createdAt: DateTime.now(),
            payload: ["Order Update", "Your order has been placed."],
          ),
        ],
      ),
    );
  }

  @override
  Future<ApiResult<Translation>> getPolicy() async {
    return ApiResult.success(
      data: Translation(
        title: "Privacy Policy",
        description: "This is a demo privacy policy.",
        locale: "en",
      ),
    );
  }

  @override
  Future<ApiResult<Translation>> getTerm() async {
    return ApiResult.success(
      data: Translation(
        title: "Terms of Service",
        description: "These are demo terms of service.",
        locale: "en",
      ),
    );
  }

  @override
  Future<ApiResult> updateNotification(
    List<NotificationData>? notifications,
  ) async {
    return ApiResult.success(data: null);
  }
}
