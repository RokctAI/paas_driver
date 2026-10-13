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
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/models/models.dart';

/// auth_sdk-local capability: sign in with a Google ID token through
/// `api.user.login_with_google`.
///
/// The backend verifies the token (signature, expiry, issuer, audience)
/// and takes the account's email from it, so the token is the only proof
/// it accepts. base_sdk's [AuthRepositoryFacade.loginWithGoogle] sends a
/// bare email/id the backend now refuses; it is core-owned and fixed, so
/// callers downcast with `is GoogleIdTokenSignIn`, the same way as
/// [EmailCodeVerification].
abstract class GoogleIdTokenSignIn {
  Future<ApiResult<LoginResponse>> loginWithGoogleIdToken({
    required String idToken,
    String? displayName,
    String? avatar,
  });
}

/// Composition config for Google Sign-In.
class GoogleSignInConfig {
  GoogleSignInConfig._();

  /// The OAuth *web* client id Google mints the ID token for (its `aud`).
  /// Android only returns an ID token when this is set, unless the app's
  /// google-services.json already carries a web client. It must be one of
  /// the ids listed in the backend's Auth Settings > Google Client IDs.
  static String? serverClientId;
}
