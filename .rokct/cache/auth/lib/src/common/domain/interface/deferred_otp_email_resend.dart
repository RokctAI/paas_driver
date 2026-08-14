import 'package:base_sdk/src/handlers/handlers.dart';

/// auth_sdk-local capability interface for the deferred-OTP flow.
///
/// The online email flow requests its verification code via
/// `sigUp(email:)` (register_user), which a backend rejects for an account
/// that ALREADY exists — exactly the state a deferred (offline-registered,
/// background-synced) account is in. The backend exposes
/// `resend_verification_email` for that case; this interface is how the
/// deferred flow reaches it.
///
/// It is deliberately NOT added to base_sdk's [AuthRepositoryFacade]
/// (core-owned, fixed): auth_sdk's own repositories implement it alongside
/// the facade, and callers downcast with `is DeferredOtpEmailResend` — a
/// third-party facade implementation that doesn't implement it simply gets
/// no deferred email prompt (the flag stays set, nothing breaks).
abstract class DeferredOtpEmailResend {
  /// Ask the backend to (re)send the verification email for [email].
  /// Sent unauthenticated: the endpoint is allow_guest and identifies the
  /// account by the email parameter — at this point in the deferred flow
  /// the only stored token may be the local `offline:<id>` placeholder,
  /// which must never be presented as a real credential.
  Future<ApiResult<dynamic>> resendVerificationEmail({required String email});
}
