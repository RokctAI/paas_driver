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
import 'package:flutter/foundation.dart';
import 'package:base_sdk/src/constants/app_constants.dart';

import 'package:base_sdk/src/handlers/log_redaction.dart';
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
    // The routing provider authenticates EITHER by an `api_key` query
    // parameter OR by an `Authorization` header, and a
    // URL is the one part of a request that everything logs. This runs
    // after TokenInterceptor (which leaves Authorization alone on the
    // routing client — routing calls are always requireAuth: false) and
    // before the log interceptor below, so the key is off the URL by the
    // time anything can print it.
    if (routing) {
      dio.interceptors.add(const RoutingCredentialInterceptor());
    }
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          responseHeader: false,
          requestHeader: true,
          responseBody: true,
          requestBody: true,
          // Debug console output is copied verbatim into CI job logs, so
          // every line goes through the redactor first — credentials in a
          // query string and in a request header alike.
          logPrint: logRedactedLine,
        ),
      );
    }
    return dio;
  }
}

/// Prints [object] with every credential in it withheld. The `logPrint`
/// hook for any Dio `LogInterceptor` in the fleet — never wire a raw
/// `print`/`debugPrint` into one.
void logRedactedLine(Object? object) => debugPrint(redactLogText(object));

/// Moves the routing provider's API key out of the query string and into
/// the `Authorization` header.
///
/// The provider accepts either (an unauthenticated GET answers 401
/// "Authorization field missing"; the header and the `api_key` parameter
/// are equivalent thereafter), and the header keeps the secret out of the
/// URL entirely — out of Dio's own logging, out of the network error
/// funnel's telemetry, and out of every proxy and server access log
/// between the device and the provider, which no amount of redaction on
/// this side can reach.
///
/// Callers may keep passing `api_key` as a query parameter: this strips
/// any credential-named parameter from a routing request and promotes its
/// value to the header, so no call site can reintroduce the leak.
class RoutingCredentialInterceptor extends Interceptor {
  const RoutingCredentialInterceptor({this.apiKey});

  /// Test seam / override. Null means [AppConstants.routingKey].
  final String? apiKey;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final String promoted = _stripCredentialParameters(options);
    final String configured = apiKey ?? AppConstants.routingKey;
    final String key = configured.isNotEmpty ? configured : promoted;
    if (key.isNotEmpty) {
      options.headers['Authorization'] = key;
    }
    handler.next(options);
  }

  /// Removes every credential-named query parameter from [options] — both
  /// the structured `queryParameters` map and anything appended to the
  /// path — and returns the first value found, so a call site that only
  /// ever passed the key as a parameter still authenticates.
  String _stripCredentialParameters(RequestOptions options) {
    String found = '';
    options.queryParameters.removeWhere((String name, dynamic value) {
      if (!isSensitiveQueryParameter(name)) return false;
      if (found.isEmpty && value != null) found = value.toString();
      return true;
    });
    final int mark = options.path.indexOf('?');
    if (mark >= 0) {
      final String query = options.path.substring(mark + 1);
      final List<String> kept = <String>[];
      for (final String pair in query.split('&')) {
        final int eq = pair.indexOf('=');
        final String name = eq <= 0 ? pair : pair.substring(0, eq);
        if (isSensitiveQueryParameter(safeDecodeQueryComponent(name))) {
          if (found.isEmpty && eq > 0) {
            found = safeDecodeQueryComponent(pair.substring(eq + 1));
          }
          continue;
        }
        kept.add(pair);
      }
      options.path = kept.isEmpty
          ? options.path.substring(0, mark)
          : '${options.path.substring(0, mark)}?${kept.join('&')}';
    }
    return found;
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
