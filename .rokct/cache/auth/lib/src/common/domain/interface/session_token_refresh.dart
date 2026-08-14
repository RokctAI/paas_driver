/// auth_sdk-local capability interface for session token rotation.
///
/// The backend keeps access tokens alive for 24h and exposes
/// `paas.api.auth.refresh` to rotate them with the refresh token minted at
/// login. The rotation itself is automatic — base_sdk's
/// `TokenRefreshService` / `TokenRefreshInterceptor` refresh proactively at
/// expiry and on 401 — but flows that want to renew explicitly (e.g. a
/// session-restore probe at app boot) reach it through this capability.
///
/// It is deliberately NOT added to base_sdk's [AuthRepositoryFacade]
/// (core-owned, fixed): auth_sdk's own repositories implement it alongside
/// the facade, and callers downcast with `is SessionTokenRefresh` — a
/// facade implementation that doesn't implement it simply gets no explicit
/// renewal hook, and the automatic interceptor path still applies.
abstract class SessionTokenRefresh {
  /// Rotate the session using the stored refresh token. Returns true when
  /// a new access token has been persisted; false leaves the caller with
  /// the usual forced-re-login behavior (an auth-level rejection has
  /// already cleared the stored session credentials).
  Future<bool> refreshSession();
}
