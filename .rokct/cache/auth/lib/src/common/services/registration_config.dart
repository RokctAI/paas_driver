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

// compliance-ignore-file: obs-flutter-trace (false positive: this file makes
// no network calls at all — it is pure composition config plus a static
// terms/DOB hand-off with no imports; the register_user request itself goes
// through AuthRepository over base_sdk's trace-propagating PlatformGateway,
// and the check fires solely because the file's path contains "services")

/// Composition-declared registration capabilities + the pending terms/DOB
/// hand-off between the register form and the sign-up calls.
///
/// [AuthRegistrationConfig] is auth_sdk's registration twin of the
/// session-policy shell: auth_sdk owns the register FLOW, but which extra
/// fields this particular app's registration asks for is composition DATA.
/// Every flag defaults to off, so apps whose manifests contribute nothing
/// get exactly the form (and exactly the register_user payload) they had
/// before this file existed. The app's home SDK flips a flag through the
/// existing manifest "integrations" channel, targeting the
/// `// @auth-registration-config` placeholder in the installed
/// auth_route_pages.dart shell (e.g. lms_sdk contributing
/// `AuthRegistrationConfig.collectsBirthDate = true;` because Supacharge's
/// league needs age to let adults self-qualify for full-name display).
class AuthRegistrationConfig {
  AuthRegistrationConfig._();

  /// Whether the register form asks for a date of birth. OFF by default —
  /// only a composition whose home SDK declares the need collects age.
  static bool collectsBirthDate = false;
}

/// The register form's pending terms acceptance + birth date, read by
/// AuthRepository when it builds the register_user payload.
///
/// A static hand-off (not new repository parameters) on purpose: the
/// sign-up surface is base_sdk's fixed AuthRepositoryFacade interface and
/// UserModel, neither of which auth_sdk may widen. The form overwrites both
/// slots on every submit, so the values a sign-up call reads are always the
/// ones from the submission that triggered it — including the deferred
/// offline path, whose later `auth.register` sync replay goes through the
/// same repository call in the same app session.
class RegistrationTerms {
  RegistrationTerms._();

  /// Set by the register form's submit action: creating the account IS the
  /// acceptance ("By creating an account you agree to the Terms and
  /// Privacy Policy" — the inline line above the register button).
  static bool termsAccepted = false;

  /// The date of birth entered on the register form, when
  /// [AuthRegistrationConfig.collectsBirthDate] asked for one.
  static DateTime? birthDate;

  /// Extra register_user payload entries for the pending submission —
  /// merged over UserModel.toJsonForSignUp() by the repository. Empty (so
  /// the wire payload is byte-identical to the pre-terms one) until the
  /// form records an acceptance.
  static Map<String, dynamic> signUpExtras() => {
        if (termsAccepted) 'terms_accepted': 1,
        if (birthDate != null) 'birth_date': formatBirthDate(birthDate!),
      };

  /// register_user expects an ISO "YYYY-MM-DD" date.
  static String formatBirthDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
