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

// Ray, 2026-10-03: "using app offline cant be taken as an error". On the
// launcher with no backend, signing in toasted "We couldn't reach the
// server. Please try again." The login screen now treats a backend that
// never answered like a dead radio: it takes the offline sign-in path and
// shows no connection toast. A refusal the server actually sent still
// shows.
//
// LoginNotifier itself cannot be constructed standalone (OfflineAuthService
// needs the host's generated drift accessors; see
// auth_unreachable_toast_test.dart), so this pins the decision and the
// branch that acts on it.

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';

import 'package:auth_sdk/src/common/services/offline_login_decision.dart';

String _failureFor(DioExceptionType type) => AppHelpers.errorHandler(
      DioException(
        requestOptions: RequestOptions(path: '/api/method/platform.gateway'),
        type: type,
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocalStorage.init();
  });

  group('a sign-in against a backend that never answers', () {
    test('a refused connection is offline use, not an error', () {
      expect(
        loginFailureMeansOffline(
          _failureFor(DioExceptionType.connectionError),
        ),
        isTrue,
      );
    });

    test('a timeout is offline use, not an error', () {
      expect(
        loginFailureMeansOffline(
          _failureFor(DioExceptionType.connectionTimeout),
        ),
        isTrue,
      );
    });

    test('the server\'s own refusal is still an error', () {
      expect(loginFailureMeansOffline('Invalid login credentials'), isFalse);
      expect(loginFailureMeansOffline(''), isFalse);
    });
  });

  test('login() takes the offline path on that failure, before any toast', () {
    final src = File(
      'lib/src/common/application/auth/login/login_notifier.dart',
    ).readAsStringSync();
    final login = src.substring(
      src.indexOf('Future<void> login(BuildContext context)'),
      src.indexOf('Future<void> _loginOffline('),
    );
    final offline = login.indexOf('loginFailureMeansOffline(');
    final hop = login.indexOf('await _loginOffline(context);', offline);
    final toast = login.indexOf('AuthErrorPresenter.show(');
    expect(offline, isNonNegative);
    expect(hop, isNonNegative);
    expect(hop < toast, isTrue,
        reason: 'the offline hop must run before the error presenter');
  });
}
