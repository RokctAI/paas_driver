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


import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';

/// Boot-time tenant remote config (the `paas.api.remote_config.get_remote_config` API base
/// itself maps in its Frappe manifest).
///
/// Absorbed from paas_manager's retired host `lib/utils/app_initializer.dart`
/// (manager migration M5): the tenant site publishes per-app overrides for a
/// small set of [AppConstants] values, fetched once at startup BEFORE the
/// first frame so form pages read the tenant's phone-field policy rather
/// than the dart-define defaults. Wire it per app flavor as a `boot_hooks`
/// manifest entry (see base_sdk's manifest `app_type.manager` block):
///
///   await RemoteConfigService.initialize(appType: 'Manager');
///
/// Overridable keys (paas_manager#28 semantics — every target is an
/// env-initialized MUTABLE static on [AppConstants], never const):
///
///  * `webUrl`
///  * the auth phone-field set: `isSpecificNumberEnabled`,
///    `isNumberLengthAlwaysSame`, `countryCodeISO`, `showFlag`,
///    `showArrowIcon`
///  * `demoLatitude` / `demoLongitude`
///
/// `AppConstants.baseUrl` and `AppConstants.adminPageUrl` are deliberately
/// NOT overridable — the fetch itself targets `baseUrl`, so letting the
/// response move it would be circular. The legacy host also carried
/// `chatGpt` / `imageBaseUrl` overrides; nothing in any composed SDK reads
/// either constant, so they were dropped rather than absorbed.
///
/// Failure-tolerant by design: a non-200, a malformed body, or any thrown
/// error leaves every constant at its dart-define default and the app boots
/// normally — remote config is an override channel, not a boot dependency.
abstract class RemoteConfigService {
  RemoteConfigService._();

  /// Fetches the remote config (gateway cmd `api.remote_config.get_remote_config`
  /// with `app_type` in the payload) from the tenant site
  /// ([AppConstants.baseUrl]) and applies any present overrides. Runs over
  /// plain http (boot happens before DI is up, so the DI'd PlatformGateway
  /// client is not available), but still speaks the gateway envelope.
  static Future<void> initialize({required String appType}) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}$kPlatformGatewayPath'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'cmd': 'api.remote_config.get_remote_config',
          'payload': {'app_type': appType},
        }),
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        debugPrint(
          '==> remote config fetch failed, status: ${response.statusCode}',
        );
        return;
      }
      final dynamic config = jsonDecode(response.body)['message'];
      if (config == null) return;

      String? getString(String key) => config[key]?.toString();
      bool? getBool(String key) {
        final dynamic value = config[key];
        if (value == null) return null;
        return value == 1 || value == true || value == 'true';
      }

      double? getDouble(String key) =>
          double.tryParse(config[key]?.toString() ?? '');

      final webUrl = getString('webUrl');
      if (webUrl != null) AppConstants.webUrl = webUrl;

      /// auth phone fields
      final isSpecificNumberEnabled = getBool('isSpecificNumberEnabled');
      if (isSpecificNumberEnabled != null) {
        AppConstants.isSpecificNumberEnabled = isSpecificNumberEnabled;
      }
      final isNumberLengthAlwaysSame = getBool('isNumberLengthAlwaysSame');
      if (isNumberLengthAlwaysSame != null) {
        AppConstants.isNumberLengthAlwaysSame = isNumberLengthAlwaysSame;
      }
      final countryCodeISO = getString('countryCodeISO');
      if (countryCodeISO != null) AppConstants.countryCodeISO = countryCodeISO;
      final showFlag = getBool('showFlag');
      if (showFlag != null) AppConstants.showFlag = showFlag;
      final showArrowIcon = getBool('showArrowIcon');
      if (showArrowIcon != null) AppConstants.showArrowIcon = showArrowIcon;

      final demoLatitude = getDouble('demoLatitude');
      if (demoLatitude != null) AppConstants.demoLatitude = demoLatitude;
      final demoLongitude = getDouble('demoLongitude');
      if (demoLongitude != null) AppConstants.demoLongitude = demoLongitude;

      debugPrint('==> remote config initialized');
    } catch (e) {
      debugPrint('==> error initializing remote config: $e');
    }
  }
}
