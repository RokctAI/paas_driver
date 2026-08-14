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
