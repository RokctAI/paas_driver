## 1.4.0

* `session_policy` fallback role (`"*"`): an `allowed_roles` entry with role
  `"*"` declares a keep-session fallback — an authenticated account whose
  role matches no other entry is ADMITTED (token persisted, session kept)
  and lands on the fallback entry's route instead of being rejected. Exact
  roles always win over `"*"`; role-less/offline sessions can only land on
  the fallback route, never on an exact-role landing. This is the driver
  composition's D1 shape (deliveryman -> `/home`, everyone else ->
  `/become-driver` with a live session so the courier request is filed as
  the signed-in user, as delivery_sdk 1.3.0 declares). Policies without a
  `"*"` entry are untouched: non-matching roles are still rejected with no
  persisted session (manager's seller-only gate behaves bit-for-bit as
  before), and `rejection_*` keys keep working for them.

## 1.3.0

* Deferred-OTP auto-routing (`PendingOtpGate`): when an offline-registered
  account's background sync completes, the app now takes the user into the
  existing OTP confirmation sheet by itself — at boot/session-restore, on
  app resume, and promptly after a sync that finishes mid-session — instead
  of leaving the `pending_otp_verification` flag unread. Installed into the
  composed app's `main()` via the new manifest `boot_hooks` entry; prompts
  only the flagged account's own session, and a dismissed sheet re-prompts
  on the next trigger (the flag is only cleared by verify success).
* `RegisterConfirmationPage.isDeferredOtp`: verify success just closes the
  sheet (the account already exists — no follow-on registration form), and
  phone codes use the backend sendOtp/verifyPhone pair even under
  `AppConstants.isPhoneFirebase`, since only `verifyPhone` lifts the
  backend's unverified-account limit.
* `DeferredOtpEmailResend`: auth_sdk-local repository capability for the
  backend's `resend_verification_email` — the email-OTP send that works for
  an account that already exists (the pre-registration `sigUp` send would
  be rejected with "already exists").

## 1.1.0

* `AuthSessionPolicy` seam: which roles may sign in and where each lands is
  now composition data (manifest `session_policy`, injected into the
  installed `auth_session_policy.dart` shell by the installer's
  `update_session_policy()`), consulted by every login variant (email,
  offline, Google, Facebook, Apple). No declared policy keeps the previous
  allow-all `isDemo ? replaceUiTypeRoute : goHome` behavior exactly.
  Rejected accounts get no persisted token.
* Login page no longer crashes at init in apps composed without an
  onboarding SDK: the `EmbeddedWidgets.I.introPage()` lookup is guarded and
  the Skip affordance is hidden when no intro exists.

## 0.0.1

* TODO: Describe initial release.
