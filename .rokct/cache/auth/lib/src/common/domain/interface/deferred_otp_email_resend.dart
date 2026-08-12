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
  /// Requires the account's session token — the deferred flow only runs
  /// while the synced account's own token is active, so that holds.
  Future<ApiResult<dynamic>> resendVerificationEmail({required String email});
}
