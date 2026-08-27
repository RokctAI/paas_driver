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

  static Future<bool> connectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.ethernet) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      return true;
    }
    return false;
  }

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
    var connectivityResult = await (Connectivity().checkConnectivity());
    bool hasConnection =
        connectivityResult.contains(ConnectivityResult.mobile) ||
            connectivityResult.contains(ConnectivityResult.ethernet) ||
            connectivityResult.contains(ConnectivityResult.wifi);

    if (!hasConnection) {
      // Automatically show dialog when no connection
      if (context.mounted) AppHelpers.showNoConnectionDialog(context);
    }

    return hasConnection;
  }

  // Alternative: Replace the existing method to always show dialog
  static Future<bool> connectivityAndShowDialog(BuildContext context) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    bool hasConnection =
        connectivityResult.contains(ConnectivityResult.mobile) ||
            connectivityResult.contains(ConnectivityResult.ethernet) ||
            connectivityResult.contains(ConnectivityResult.wifi);

    if (!hasConnection) {
      if (context.mounted) AppHelpers.showNoConnectionDialog(context);
    }

    return hasConnection;
  }
}
