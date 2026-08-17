import 'package:dio/dio.dart';

import 'package:base_sdk/src/di/injection.dart';

/// The universal platform entry-point method name — the ONE place the
/// gateway's dotted method lives, so a future rename is a single-constant
/// change. Registered app-side (rCore hooks) as
/// `rokct.platform.api -> rcore.platform.api.execute`, which routes by the
/// site's role (tenant/control) server-side; the paas shell exposes the
/// same key, so which backend answers is decided purely by
/// `AppConstants.baseUrl`.
const String kPlatformGatewayMethod = 'rokct.platform.api';

/// The full request path derived from [kPlatformGatewayMethod]. Uses the
/// versioned `/api/v1/method/` prefix (project ruling: every client-facing
/// endpoint URL is `/api/v1/method/<name>`; the Frappenize fork mounts the
/// same v1 rules under both `/api` and `/api/v1`). Never hardcode this
/// elsewhere — import it.
const String kPlatformGatewayPath = '/api/v1/method/$kPlatformGatewayMethod';

/// Client for the universal platform gateway: every backend call is a
/// `POST` to [kPlatformGatewayPath] with a JSON body of
/// `{"cmd": "<prefix-free dotted name>", "payload": {...}}`.
///
/// `cmd` is app-agnostic — the leading app segment of the legacy dotted
/// endpoints is dropped (`paas.api.lms.list_courses` becomes
/// `api.lms.list_courses`); the gateway resolves it against the composed
/// app's own whitelist server-side, so the same SDK code runs against any
/// backend the baseUrl points at.
///
/// Response shape: the shared Dio stack's `FrappeResponseInterceptor`
/// already unwraps the top-level `message` envelope on 2xx, and the
/// gateway returns the target method's own return value inside that same
/// single envelope — so what [tenant] answers is exactly what a direct
/// dotted call answered. Do NOT unwrap `message` again here.
class PlatformGateway {
  const PlatformGateway();

  /// Executes [cmd] on the tenant backend selected by the client's
  /// baseUrl, with [payload] as the method's kwargs. Returns the (already
  /// interceptor-unwrapped) response body.
  Future<dynamic> tenant(String cmd, [Map<String, dynamic>? payload]) =>
      call(cmd, payload: payload);

  /// [tenant] with the full knobs the repositories need:
  /// [requireAuth] mirrors `HttpService.client`'s flag (guest endpoints
  /// pass false), and [options] carries per-request headers such as the
  /// idempotency key.
  Future<dynamic> call(
    String cmd, {
    Map<String, dynamic>? payload,
    bool requireAuth = true,
    Options? options,
  }) async {
    // Resolved lazily per call (same as the repositories' `dioHttp` use),
    // so test harnesses that swap the registered HttpService keep working.
    final client = dioHttp.client(requireAuth: requireAuth);
    final response = await client.post(
      kPlatformGatewayPath,
      data: {
        'cmd': cmd,
        if (payload != null) 'payload': payload,
      },
      options: options,
    );
    return response.data;
  }
}
