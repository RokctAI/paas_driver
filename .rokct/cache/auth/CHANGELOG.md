## 1.8.8

* `OfflineAuthService.registerOffline` resumes a pending (unsynced)
  local-first registration instead of failing it: a retried Register press
  for the same phone/email refreshes the existing row's details and
  returns the same row id (so the sync push keeps its idempotency key).
  Previously any existing row — including the one the previous offline
  attempt itself wrote — failed with "already exists", which made
  `register`/`registerWithPhone` skip their offline fallback and surface
  the generic "something went wrong with the server" line on every retry
  while the backend was down (driver Windows report, 2026-08-26). A row
  that already `synced` still fails as before — that account exists on
  the backend and the user should log in.
* `RegisterNotifier.register`/`registerWithPhone`: when the backend is
  unreachable (non-definitive status) AND the local-first write failed,
  show the local error's authored user copy instead of falling through to
  the generic server line — same surface `_completeOffline` already uses
  for a local failure.

## 1.8.5

* `MockAuthRepository._demoRolesByEmail` gains `driver@demo.rokct.ai` ->
  `deliveryman` and `manager@demo.rokct.ai` -> `seller`, so guided tours
  (and manual demo sign-ins) can enter the paas_driver and paas_manager
  compositions through their real login flows. The role strings are the
  exact values those apps' declared session policies admit
  (zones/delivery manifest `app_type.driver.session_policy`: deliveryman
  -> /home; commerce/merchants manifest
  `app_type.manager.session_policy`: seller -> /main). Additive only —
  the existing partner/admin mappings and the default customer role are
  unchanged.

## 1.8.3

* `AuthRepository` calls the registered composed aliases instead of
  unregistered paths that 404 on composed backends:
  `paas.api.user.user.login` -> `paas.api.user.login`; bare
  `paas.api.<fn>` -> `paas.api.user.<fn>` for
  `send_phone_verification_code`, `verify_phone_code`, `forgot_password`,
  `register_user` (x3), `forgot_password_confirm`, `login_with_google`;
  `paas.api.verify_my_email` -> `paas.tenant.api.verify_my_email` (the
  only registered name for that endpoint, in auth/frappe/manifest.json);
  and `paas.api.resend_verification_email` ->
  `paas.api.user.resend_verification_email` (consistency only — the short
  form is also registered). Completes the users_sdk alias fix (#20),
  which deliberately deferred this file behind #16.

## 1.8.2

Security release. (Versioned above main's 1.8.0 and the 1.8.1 claimed by
the in-flight AuthRepository alias-fix PR, Users #24.)

* **Random sync password** (`OfflineAuthService.syncOne`): the offline-sync
  push used to register the backend account with the local row id — a
  predictable epoch-microsecond timestamp — as its durable login password.
  It now sends a cryptographically random secret (32 bytes from
  `Random.secure()`, base64url, 256 bits — `generateSecurePassword` in
  `src/common/services/secure_password.dart`), generated once per row per
  app run and held in memory until the sync succeeds (so a retried push
  re-sends the same value), then discarded: post-sync access is OTP
  verification -> session token, and password login stays recoverable via
  the forgot-password flow.
* **Forced credential rotation** (`SessionPasswordRotation` +
  `OfflineAuthService.onDeferredVerificationCompleted` /
  `retryPendingPasswordRotations`): accounts synced by older releases still
  carry the guessable timestamp password on the backend. The moment a
  deferred account completes OTP verification and receives its first real
  session token, the client now calls the backend's session-scoped
  `update_password` with a fresh random secret (also discarded). Failures
  are non-fatal: a persisted pending flag is retried post-frame by
  `PendingOtpGate` on every boot and app resume, and never blocks login or
  verification. Accounts that BOTH synced AND verified under old releases
  are not client-identifiable (verification re-mints the session token, so
  the stored row token is stale) and are not rotated — see the PR for the
  declared limitation.
* **Honest deferred email resend**: `resendVerificationEmail` now sends
  `requireAuth: false`. The endpoint is allow_guest and identifies the
  account by the email parameter; previously the call presented the local
  `offline:<id>` placeholder as a Bearer credential and only worked because
  the backend's Bearer parser falls through to Guest on malformed tokens.
* Comment fixes: the offline row id is documented as a local-only
  epoch-derived identifier (it was mislabeled "local UUID"), never a
  credential.
* Rotation calls the registered composed alias
  `paas.api.user.update_password` (per the users/frappe manifest's
  whitelisted_methods), not the unregistered raw module path
  `paas.api.user.user.update_password` — same double-segment bug class
  Users #20/#24 fixed elsewhere.

## 1.8.0

* Session token refresh (requires base_sdk >= 1.12.0). Login now persists
  the backend's full token contract — `refresh_token` (to secure
  keystore/keychain storage) and `expires_at` — instead of dropping both,
  so base_sdk's new single-flight `TokenRefreshService` can silently
  rotate the 24h access token (proactively at expiry, and on 401 with one
  retry) instead of dumping the user on the login screen every day. New
  `SessionTokenRefresh` capability interface (same pattern as
  `DeferredOtpEmailResend`): `AuthRepository` implements it by delegating
  to the base_sdk service; facade implementations that skip it simply get
  no explicit renewal hook, the automatic interceptor path still applies.
  When rotation itself fails at the auth level, the stored session is
  cleared and the existing per-notifier 401 -> login routing takes over.
  Version 1.7.0 is claimed by the idempotency-key PR (Users #16), hence
  1.8.0. (The offline-password PR, Users #19, ships above this as 1.8.2.)

## 1.7.0

* `sigUpWithData` sends an `X-Idempotency-Key` header (optional
  `idempotencyKey` named param threaded through the base_sdk
  `AuthRepositoryFacade`): the server's `register_user` endpoint is already
  `@idempotent`, so a retried registration upload now replays the stored
  response instead of double-registering. The key is stable per local
  account row (`OfflineAuthService.registrationIdempotencyKey`, row id +
  identifier, well under the backend's 140-char cap) and is shared by the
  offline-sync push (`syncOne`) and the inline online register path, so a
  retry through either flow dedupes against the other. Requires base_sdk
  with the `idempotencyKey` param on `AuthRepositoryFacade.sigUpWithData` —
  merge this SDK BEFORE that base_sdk change (implementers may carry extra
  optional named params; the interface declaring one that implementers
  lack would not compile). Direct callers without a natural stable key
  simply send no header.

## 1.6.0

* Desktop platform guards (`src/common/services/platform_support.dart`):
  social sign-in buttons (Facebook/Google) are hidden on Windows/Linux,
  where google_sign_in / flutter_facebook_auth have no implementation
  (kept on Android/iOS/web/macOS, where they do); Firebase phone-OTP
  sends fail fast with a translated snackbar on non-mobile platforms
  instead of hanging a spinner (`verifyPhoneNumber` is Android/iOS-only);
  and FCM token sync after login/register/confirm goes through a shared
  `syncFcmToken` helper that silently skips on Windows/Linux (where
  Firebase is never initialized) and swallows messaging failures instead
  of throwing `[core/no-app]` into the auth flow.

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
