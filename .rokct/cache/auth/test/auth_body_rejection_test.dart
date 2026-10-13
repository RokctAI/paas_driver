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

// api_response answers HTTP 200 with the real outcome in the body's
// status_code. A wrong password (401), an unverified account (403) and a
// wrong or expired reset code (400) used to be taken as success: login
// saved an empty token, reset went on to the new-password step. The real
// gateway runs here against a recording adapter that answers like the
// backend does.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/handlers/http_service.dart';
import 'package:base_sdk/src/services/local_storage.dart';

import 'package:auth_sdk/src/common/infrastructure/repositories/auth_repository.dart';

class _BodyAdapter implements HttpClientAdapter {
  _BodyAdapter(this.body);

  final Map<String, dynamic> body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      // The stub Dio carries no FrappeResponseInterceptor, so the body is
      // served already unwrapped, as the gateway hands it on.
      jsonEncode(body),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _StubHttpService extends HttpService {
  _StubHttpService(this.adapter);

  final _BodyAdapter adapter;

  @override
  Dio client({bool requireAuth = false, bool routing = false}) =>
      Dio()..httpClientAdapter = adapter;
}

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> answer(Map<String, dynamic> body) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocalStorage.init();
    if (getIt.isRegistered<HttpService>()) {
      await getIt.unregister<HttpService>();
    }
    getIt.registerSingleton<HttpService>(_StubHttpService(_BodyAdapter(body)));
  }

  tearDown(() async {
    if (getIt.isRegistered<HttpService>()) {
      await getIt.unregister<HttpService>();
    }
  });

  test('a wrong password is a failure carrying the backend message', () async {
    await answer(<String, dynamic>{
      'message': 'Invalid credentials',
      'status_code': 401,
    });
    final result = await AuthRepository().login(email: 'a@b.c', password: 'x');
    result.when(
      success: (_) => fail('a 401 body must not be a successful login'),
      failure: (error, status) {
        expect(error, 'Invalid credentials');
        expect(status, 401);
      },
    );
  });

  test('an unverified account (403) is a failure', () async {
    await answer(<String, dynamic>{
      'message': 'Please verify your email',
      'status_code': 403,
    });
    final result = await AuthRepository().login(email: 'a@b.c', password: 'x');
    expect(result, isA<Failure<dynamic>>());
  });

  test('a wrong or expired reset code is a failure', () async {
    await answer(<String, dynamic>{
      'message': 'Invalid or expired verification code',
      'status_code': 400,
    });
    final result = await AuthRepository().forgotPasswordConfirm(
      verifyCode: '000000',
      email: 'a@b.c',
    );
    result.when(
      success: (_) => fail('a 400 body must not confirm the reset'),
      failure: (error, status) => expect(status, 400),
    );
  });
}
