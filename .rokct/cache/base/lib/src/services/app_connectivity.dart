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


import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

/// Result of [AppConnectivity.backendStatus]: the backend answered normally
/// ([up]), answered but reports the site is in maintenance ([maintenance]),
/// or could not be reached at all ([down]).
enum BackendStatus { up, maintenance, down }

abstract class AppConnectivity {
  AppConnectivity._();

  /// Whether one `connectivity_plus` answer describes a device with a
  /// network — the ONE definition of "online" in the fleet; every surface
  /// that asks the radio asks here.
  ///
  /// The plugin reports [ConnectivityResult.none] exactly when the active
  /// network carries no `NET_CAPABILITY_INTERNET` (see the Android plugin's
  /// `Connectivity.getCapabilitiesList`), so EVERY other answer is a
  /// network the OS believes can carry traffic:
  ///
  ///  * [ConnectivityResult.vpn] — the active network on a phone with a VPN
  ///    up, which is what `getActiveNetwork()` hands the plugin there;
  ///  * [ConnectivityResult.other] — an internet-capable transport the
  ///    plugin has no name for (the Windows/Linux catch-all, tethering);
  ///  * [ConnectivityResult.bluetooth] — a tethered Bluetooth network.
  ///
  /// Admitting only mobile/ethernet/wifi called all three offline. Ray,
  /// 2026-09-19: "going to profile i get offline toast" — on a phone that
  /// was online. The profile's fetch gate (`ProfileNotifier.fetchUser`)
  /// asks this question, and on false shows the no-connection snackbar
  /// WITHOUT attempting the fetch, so a device whose active network the
  /// plugin names anything but those three got the offline toast and no
  /// profile.
  ///
  /// An empty list is offline: no answer is not an answer of "online".
  static bool isOnline(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);

  static Future<bool> connectivity() async =>
      isOnline(await Connectivity().checkConnectivity());

  // True backend reachability: unlike connectivity() (radio-only, which a
  // Wi-Fi network without internet false-passes), this probes the tenant
  // backend's guest api_status endpoint. On-demand only — never poll it.
  static Future<bool> backendAvailability({
    Duration timeout = const Duration(seconds: 5),
    http.Client? client,
  }) async =>
      await backendStatus(timeout: timeout, client: client) ==
      BackendStatus.up;

  // Tri-state variant of backendAvailability() for flows that must
  // distinguish a backend in maintenance mode from one that is unreachable.
  static Future<BackendStatus> backendStatus({
    Duration timeout = const Duration(seconds: 5),
    http.Client? client,
  }) async {
    try {
      if (!await connectivity()) return BackendStatus.down;
      // Raw http (pre-DI) — POST the platform gateway envelope directly;
      // the DI'd PlatformGateway client is not in play here. The gateway
      // returns the same single `message` envelope a direct dotted call
      // did, so the parsing below is unchanged.
      final uri = Uri.parse('${AppConstants.baseUrl}$kPlatformGatewayPath');
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode({'cmd': 'api.system.api_status'});
      final response = await (client == null
              ? http.post(uri, headers: headers, body: body)
              : client.post(uri, headers: headers, body: body))
          .timeout(timeout);
      if (response.statusCode != 200) return BackendStatus.down;
      final dynamic message = jsonDecode(response.body)['message'];
      final status = message?['data']?['status']?.toString();
      return status == 'maintenance'
          ? BackendStatus.maintenance
          : BackendStatus.up;
    } catch (e) {
      return BackendStatus.down;
    }
  }

  // New method that automatically shows dialog when no connection
  static Future<bool> connectivityWithDialog(BuildContext context) async {
    final bool hasConnection = await connectivity();

    if (!hasConnection) {
      // Automatically show dialog when no connection
      if (context.mounted) AppHelpers.showNoConnectionDialog(context);
    }

    return hasConnection;
  }

  // Alternative: Replace the existing method to always show dialog
  static Future<bool> connectivityAndShowDialog(BuildContext context) async {
    final bool hasConnection = await connectivity();

    if (!hasConnection) {
      if (context.mounted) AppHelpers.showNoConnectionDialog(context);
    }

    return hasConnection;
  }
}
