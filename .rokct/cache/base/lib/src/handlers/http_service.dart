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


import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:base_sdk/src/constants/app_constants.dart';

import 'package:base_sdk/src/handlers/token_interceptor.dart';
import 'package:base_sdk/src/handlers/token_refresh_service.dart';
import 'package:base_sdk/src/services/timing_telemetry.dart';

class HttpService {
  Dio client({bool requireAuth = false, bool routing = false}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: routing ? AppConstants.drawingBaseUrl : AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Accept':
              'application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8',
          'Content-type': 'application/json',
        },
      ),
    )
      ..interceptors.add(TimingInterceptor())
      ..interceptors.add(TokenInterceptor(requireAuth: requireAuth))
      // 401 -> single-flight token rotation -> one retry (see
      // token_refresh_service.dart for the loop guards).
      ..interceptors.add(const TokenRefreshInterceptor())
      ..interceptors.add(const FrappeResponseInterceptor());
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          responseHeader: false,
          requestHeader: true,
          responseBody: true,
          requestBody: true,
        ),
      );
    }
    return dio;
  }
}

class FrappeResponseInterceptor extends Interceptor {
  const FrappeResponseInterceptor();

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.data is Map && response.data.containsKey('message')) {
      response.data = response.data['message'];
    }
    handler.next(response);
  }
}
