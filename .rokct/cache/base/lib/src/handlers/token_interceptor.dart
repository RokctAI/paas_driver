import 'package:dio/dio.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/telemetry.dart';

class TokenInterceptor extends Interceptor {
  final bool requireAuth;

  TokenInterceptor({required this.requireAuth});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Always add the mobile client header
    options.headers.addAll({'X-Client-Type': 'mobile'});
    // Trace id via the ONE shared generator (ADR-006) — the telemetry
    // backend reads this header family to stitch requests to error logs.
    options.headers.putIfAbsent('x-trace-id', generateTraceId);

    // Add authentication token if needed
    final String token = LocalStorage.getToken();
    if (token.isNotEmpty && requireAuth) {
      options.headers.addAll({'Authorization': 'Bearer  $token'});
    }

    handler.next(options);
  }
}
