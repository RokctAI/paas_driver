// Copyright (c) 2026 RokctAI
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
import 'package:base_sdk/src/handlers/http_service.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/secure_storage.dart';

/// Single-flight client for the backend's token-rotation endpoint
/// (gateway cmd [refreshCmd] — users/auth/frappe/src/api/auth/auth.py).
///
/// The backend rotates EVERYTHING on each call (api_key, api_secret,
/// refresh token, expiry), and the refresh token is single-use: two
/// concurrent refresh calls would race, with the loser invalidating the
/// winner's freshly-minted session. [HttpService] builds a new Dio per
/// repository call, so per-instance state cannot serialize the calls —
/// the in-flight future is static and shared process-wide instead: the
/// first caller starts the exchange, every concurrent caller awaits the
/// same future.
///
/// Failure contract (from the backend): an invalid/unknown refresh token
/// comes back as HTTP 200 with `{status: false}` — NOT as an HTTP error —
/// so the body is branched on, not the status code. Auth-level failures
/// clear the session credentials and fire [onSessionExpired]; transient
/// network errors leave the stored session untouched so a later attempt
/// can still succeed.
abstract class TokenRefreshService {
  TokenRefreshService._();

  /// Gateway cmd (prefix-free tenant alias of `auth.api.auth.auth.refresh`,
  /// registered in the auth module's frappe manifest). The exchange is a
  /// `POST` to [kPlatformGatewayPath] carrying this cmd.
  static const String refreshCmd = 'api.auth.refresh';

  /// Seconds of clock skew tolerated when deciding an access token is
  /// about to expire ([isAccessTokenExpired]). The stored `expires_at` is
  /// server time with no timezone marker, so this check is best-effort;
  /// the 401-retry path in [TokenRefreshInterceptor] is the safety net.
  static const int expirySkewSeconds = 60;

  /// Optional host hook fired after refresh fails at the auth level and
  /// the stored session credentials have been cleared. base_sdk holds no
  /// navigator/context, so it cannot route to login itself; a host app
  /// may assign this to do so globally. When left unset, the existing
  /// per-notifier `401 -> replaceLoginRoute` handling remains the
  /// fallback: the original request's 401 still propagates to its caller.
  static void Function()? onSessionExpired;

  /// Test seam: replaces the bare Dio used for the refresh call itself.
  @visibleForTesting
  static Dio Function()? dioFactoryOverride;

  static Future<bool>? _inFlight;

  @visibleForTesting
  static void resetForTesting() {
    _inFlight = null;
    dioFactoryOverride = null;
    onSessionExpired = null;
  }

  /// True when a rotation exchange is currently running.
  static bool get isRefreshing => _inFlight != null;

  /// Whether the stored access token is past (or within
  /// [expirySkewSeconds] of) its recorded `expires_at`. False when no
  /// expiry is recorded (e.g. sessions minted by flows that return no
  /// refresh contract), so those sessions are never proactively expired.
  static bool isAccessTokenExpired() {
    final String stored = LocalStorage.getTokenExpiry();
    if (stored.isEmpty) return false;
    final DateTime? expiry = DateTime.tryParse(stored);
    if (expiry == null) return false;
    return DateTime.now()
        .add(const Duration(seconds: expirySkewSeconds))
        .isAfter(expiry);
  }

  /// Rotate the session using the stored refresh token. Returns true when
  /// a new access token has been persisted. Concurrent callers share one
  /// backend call (single-flight).
  static Future<bool> refresh() {
    final Future<bool>? running = _inFlight;
    if (running != null) return running;
    final Future<bool> attempt = _doRefresh().whenComplete(() {
      _inFlight = null;
    });
    _inFlight = attempt;
    return attempt;
  }

  static Future<bool> _doRefresh() async {
    final String refreshToken = await SecureStorage.getRefreshToken();
    if (refreshToken.isEmpty) {
      // Nothing to renew with: the session cannot be recovered silently.
      await _expireSession();
      return false;
    }
    try {
      final Dio dio = (dioFactoryOverride ?? _bareDio)();
      final Response<dynamic> response = await dio.post(
        kPlatformGatewayPath,
        data: {
          'cmd': refreshCmd,
          'payload': {'refresh_token': refreshToken},
        },
      );
      dynamic body = response.data;
      // Frappe wraps whitelisted-method dicts under `message`. The bare
      // Dio here has no FrappeResponseInterceptor, so unwrap manually
      // (and tolerate an already-unwrapped body).
      if (body is Map && body.containsKey('message') && body['message'] is Map) {
        body = body['message'];
      }
      if (body is Map && body['status'] == true && body['data'] is Map) {
        final Map data = body['data'] as Map;
        final String newToken = data['access_token']?.toString() ?? '';
        if (newToken.isEmpty) {
          await _expireSession();
          return false;
        }
        // setToken clears the stored refresh contract, so persist the
        // rotated pair strictly after it.
        await LocalStorage.setToken(newToken);
        await SecureStorage.setRefreshToken(
          data['refresh_token']?.toString(),
        );
        await LocalStorage.setTokenExpiry(data['expires_at']?.toString());
        return true;
      }
      // HTTP 200 + status:false — the backend rejected the refresh token.
      await _expireSession();
      return false;
    } on DioException catch (e) {
      final int? code = e.response?.statusCode;
      if (code == 401 || code == 403) {
        await _expireSession();
        return false;
      }
      // Transient (timeout, connectivity, 5xx): keep the stored session;
      // the original request's failure propagates to its caller.
      debugPrint('==> token refresh transport failure: $e');
      return false;
    } catch (e) {
      debugPrint('==> token refresh failure: $e');
      return false;
    }
  }

  /// Bare client for the refresh call: deliberately NO TokenInterceptor
  /// (the exchange authenticates with the refresh token in the body, and
  /// an interceptor-bearing client could recurse into refresh) and no
  /// FrappeResponseInterceptor (the body is unwrapped manually above).
  static Dio _bareDio() => Dio(
        BaseOptions(
          baseUrl: AppConstants.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
          headers: {
            'Accept': 'application/json',
            'Content-type': 'application/json',
            'X-Client-Type': 'mobile',
          },
        ),
      );

  static Future<void> _expireSession() async {
    await LocalStorage.setToken('');
    await SecureStorage.deleteRefreshToken();
    await LocalStorage.deleteTokenExpiry();
    onSessionExpired?.call();
  }
}

/// Error interceptor wired into every [HttpService] client: a 401 on an
/// authenticated request triggers ONE single-flight refresh, then retries
/// the original request exactly once with the rotated token.
///
/// Loop guards:
///  * requests without an Authorization header are ignored (a refresh
///    cannot help an unauthenticated call);
///  * the refresh endpoint itself is never refreshed-and-retried;
///  * a retried request is stamped in `RequestOptions.extra`, so a second
///    401 on the retry propagates instead of looping.
class TokenRefreshInterceptor extends Interceptor {
  const TokenRefreshInterceptor();

  @visibleForTesting
  static const String retriedFlag = 'tokenRefreshRetried';

  /// Test seam: replaces the client used to resend the original request.
  @visibleForTesting
  static Future<Response<dynamic>> Function(RequestOptions options)?
      retrySenderOverride;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final RequestOptions options = err.requestOptions;
    final bool isAuthed = options.headers.containsKey('Authorization');
    // Every call shares the gateway path, so the refresh exchange is
    // identified by its cmd in the request body, not by path.
    final dynamic body = options.data;
    final bool isRefreshCall = options.path == kPlatformGatewayPath &&
        body is Map &&
        body['cmd'] == TokenRefreshService.refreshCmd;
    final bool alreadyRetried = options.extra[retriedFlag] == true;
    if (err.response?.statusCode != 401 ||
        !isAuthed ||
        isRefreshCall ||
        alreadyRetried) {
      return handler.next(err);
    }
    try {
      final bool refreshed = await TokenRefreshService.refresh();
      if (!refreshed) return handler.next(err);
      options.extra[retriedFlag] = true;
      // Drop the stale header; the retry client's TokenInterceptor
      // re-reads the rotated token from storage.
      options.headers.remove('Authorization');
      final Response<dynamic> response = await _resend(options);
      return handler.resolve(response);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    } catch (_) {
      return handler.next(err);
    }
  }

  static Future<Response<dynamic>> _resend(RequestOptions options) {
    final Future<Response<dynamic>> Function(RequestOptions)? sender =
        retrySenderOverride;
    if (sender != null) return sender(options);
    // Full HttpService chain so the retried response gets the same
    // treatment as any other (fresh token header, Frappe unwrap). The
    // retried-flag above keeps this from recursing.
    return HttpService().client(requireAuth: true).fetch(options);
  }
}
