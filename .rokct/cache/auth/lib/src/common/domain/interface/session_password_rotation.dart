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
