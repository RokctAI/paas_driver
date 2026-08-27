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
