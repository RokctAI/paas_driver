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

// Test double for base_sdk's HttpService, the one seam every repository
// reaches the network through (`dioHttp.client(...)` resolves it from
// GetIt, and PlatformGateway resolves it lazily per call). It records the
// requests the code under test makes and answers each one from a canned
// responder, so a repository test can assert the exact gateway `cmd` and
// payload without a server. The response handed back is the
// ALREADY-UNWRAPPED body - the live stack's FrappeResponseInterceptor
// strips the top-level `message` envelope before a repository sees it, and
// this double stands in for the stack past that point.

import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/handlers/http_service.dart';
import 'package:dio/dio.dart';

/// One request the code under test issued.
class RecordedRequest {
  final String method;
  final String path;
  final dynamic body;
  final Map<String, dynamic> queryParameters;
  final bool requireAuth;

  const RecordedRequest({
    required this.method,
    required this.path,
    required this.body,
    required this.queryParameters,
    required this.requireAuth,
  });

  /// The gateway `cmd` when [body] is a gateway envelope, else null.
  String? get cmd => body is Map ? body['cmd'] as String? : null;

  /// The gateway `payload` when [body] is a gateway envelope, else null.
  Map<String, dynamic>? get payload {
    if (body is! Map) return null;
    final payload = body['payload'];
    return payload is Map ? Map<String, dynamic>.from(payload) : null;
  }
}

typedef Responder = dynamic Function(RecordedRequest request);

class RecordingHttpService extends HttpService {
  final Responder responder;
  final List<RecordedRequest> requests = [];

  RecordingHttpService(this.responder);

  /// Registers this double as the HttpService every repository resolves.
  /// Callers pair it with `getIt.reset()` in tearDown.
  static RecordingHttpService install(Responder responder) {
    final service = RecordingHttpService(responder);
    if (getIt.isRegistered<HttpService>()) {
      getIt.unregister<HttpService>();
    }
    getIt.registerSingleton<HttpService>(service);
    return service;
  }

  RecordedRequest get single {
    if (requests.length != 1) {
      throw StateError('expected exactly one request, saw ${requests.length}');
    }
    return requests.single;
  }

  @override
  Dio client({bool requireAuth = false, bool routing = false}) {
    final dio = Dio(BaseOptions(baseUrl: 'https://gateway.test'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final recorded = RecordedRequest(
            method: options.method,
            path: options.path,
            body: options.data,
            queryParameters: Map<String, dynamic>.from(options.queryParameters),
            requireAuth: requireAuth,
          );
          requests.add(recorded);
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: responder(recorded),
            ),
          );
        },
      ),
    );
    return dio;
  }
}
