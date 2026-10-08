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

/// auth_sdk-local capability: verify the 6-digit email code by email + code
/// through `api.user.verify_email_code`, which (unlike the facade's
/// `verifyEmail` -> verify_my_email) mints a session token.
///
/// Kept out of base_sdk's [AuthRepositoryFacade] (core-owned, fixed) the
/// same way as [DeferredOtpEmailResend]: callers downcast with
/// `is EmailCodeVerification` and fall back to `verifyEmail` otherwise.
abstract class EmailCodeVerification {
  Future<ApiResult<VerifyPhoneResponse>> verifyEmailCode({
    required String email,
    required String verifyCode,
  });
}
