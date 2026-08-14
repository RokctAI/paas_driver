import 'package:base_sdk/src/handlers/handlers.dart';

/// auth_sdk-local capability interface for forced credential rotation on
/// deferred (offline-registered, background-synced) accounts.
///
/// Historically the sync path registered those accounts with a guessable
/// backend password (the local row id, an epoch timestamp). Rotation calls
/// the backend's session-scoped password-change endpoint with a fresh
/// random secret the moment the account has a real session token (right
/// after OTP verification mints one), invalidating the guessable password.
///
/// Like [DeferredOtpEmailResend], it is deliberately NOT added to
/// base_sdk's `AuthRepositoryFacade` (core-owned, fixed): auth_sdk's own
/// repositories implement it alongside the facade and callers downcast
/// with `is SessionPasswordRotation` — a third-party facade implementation
/// that doesn't implement it simply gets no client-driven rotation (the
/// pending-rotation flag stays set, nothing breaks).
abstract class SessionPasswordRotation {
  /// Set the CURRENT session user's backend password. Requires a real
  /// (non-`offline:`) session token to be active — the endpoint operates
  /// on the session user and rejects Guest.
  Future<ApiResult<dynamic>> updateSessionPassword({
    required String password,
    required String passwordConfirmation,
  });
}
