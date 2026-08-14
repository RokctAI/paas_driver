import 'package:dio/dio.dart';
import 'package:base_sdk/src/handlers/token_refresh_service.dart';
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
    String token = LocalStorage.getToken();
    if (token.isNotEmpty && requireAuth) {
      // Proactive rotation: when the stored expiry says the access token
      // is (about to be) dead, refresh before sending instead of waiting
      // for the failure. Single-flight, so concurrent requests share one
      // exchange. Best-effort: on failure the request still goes out and
      // the 401 path (TokenRefreshInterceptor / per-notifier handling)
      // takes over.
      if (TokenRefreshService.isAccessTokenExpired()) {
        await TokenRefreshService.refresh();
        token = LocalStorage.getToken();
      }
      if (token.isNotEmpty) {
        // Single space: the backend's auth hook parses the header with
        // `split(" ")[1]`, so the historical double space made it skip
        // mobile tokens entirely (core PR #42 audit, finding L3).
        options.headers.addAll({'Authorization': 'Bearer $token'});
      }
    }

    handler.next(options);
  }
}
