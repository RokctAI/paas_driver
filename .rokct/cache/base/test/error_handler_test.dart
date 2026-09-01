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


import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

/// AppHelpers.errorHandler is the single funnel every repository's catch
/// block feeds into student-facing snackbars. Contract under test:
///
///   * connection-class DioExceptions (no HTTP response ever arrived —
///     offline, DNS failure, timeouts) surface the friendly one-liner, not
///     the old null-shorted literal "null";
///   * real server responses keep the pre-existing message extraction;
///   * no input whatsoever can make it return "null" or an empty string.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  RequestOptions options() => RequestOptions(
        path: kPlatformGatewayPath,
        data: {'cmd': 'api.user.register_user'},
      );

  test(
      'connection-class DioException (null response) returns the friendly '
      'line, never "null"', () {
    const connectionTypes = [
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.unknown,
    ];
    for (final type in connectionTypes) {
      final message = AppHelpers.errorHandler(
        DioException(requestOptions: options(), type: type),
      );
      expect(message.trim(), isNotEmpty, reason: '$type');
      expect(message, isNot('null'), reason: '$type');
      // The same translation key every offline surface already shows
      // (fallback rendering: "Check your network connection").
      expect(
        message,
        AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
        reason: '$type',
      );
    }
  });

  test('a real server response keeps the existing message extraction', () {
    final e = DioException(
      requestOptions: options(),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: options(),
        statusCode: 409,
        data: {'message': 'Email already exists'},
      ),
    );
    expect(AppHelpers.errorHandler(e), 'Email already exists');
  });

  test('non-Dio errors keep their toString message', () {
    expect(AppHelpers.errorHandler(Exception('boom')), 'Exception: boom');
  });

  test('hardened fallback: no input yields "null" or an empty string', () {
    // null.toString() is the exact null-shorted chain that used to reach
    // the register screen as a red "null" toast.
    for (final input in [null, '', 'null', '   ']) {
      final message = AppHelpers.errorHandler(input);
      expect(message.trim(), isNotEmpty, reason: '"$input"');
      expect(message.trim(), isNot('null'), reason: '"$input"');
    }
  });
}
