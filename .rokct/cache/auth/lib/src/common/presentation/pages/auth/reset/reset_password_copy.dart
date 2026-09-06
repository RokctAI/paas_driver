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

import 'package:base_sdk/src/services/enums.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

/// The translation key for the reset-password sheet's instruction line,
/// matched to the app's sign-up type: the field under it is a phone field
/// for a phone sign-up and an email-or-phone field for both, and the copy
/// has to promise what the backend then sends (a code to a number, a link
/// to an address). Every variant used to read the email/link copy.
///
/// Kept out of `ResetPasswordPage` so it can be pinned for all three
/// types: `AppConstants.signUpType` is a compile-time define, and the sheet
/// itself only compiles inside a composed host (its confirmation step
/// reaches `OfflineAuthService`, whose table the composer injects into the
/// host's `AppDatabase`).
String resetPasswordCopyKey(SignUpType type) {
  switch (type) {
    case SignUpType.phone:
      return TrKeys.resetPasswordPhoneText;
    case SignUpType.both:
      return TrKeys.resetPasswordEitherText;
    case SignUpType.email:
      return TrKeys.resetPasswordText;
  }
}
