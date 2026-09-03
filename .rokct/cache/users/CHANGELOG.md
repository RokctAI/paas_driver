## 1.3.3

* `UserRepository.updateProfileImage` now sends `{'image': ...}` — the
  server's `update_profile_image(image)` kwarg — instead of `image_url`,
  which frappe dropped silently before raising a TypeError on the missing
  positional. `updatePassword` now sends `password_confirmation` alongside
  `password`: `update_password(password, password_confirmation)` needs both
  and compares them server-side, so the confirmation the facade already
  received is forwarded verbatim rather than left out. Both are Dart-side
  fixes to match the existing server signatures (Dart SDK audit
  2026-09-02, U1/U2); the `api.user.*` aliases and `ProfileResponse`
  mapping are unchanged. New `test/user_repository_payload_test.dart`
  drives the real `PlatformGateway` through a recording
  `HttpClientAdapter` and asserts the `{cmd, payload}` envelope for both
  calls (`dio` added as a dev dependency for it).

## 1.3.2

* Version-only bump so composed shells re-extract users_sdk. `SessionEndHooks`
  (`lib/src/common/services/session_end_hooks.dart`), its `users_sdk.dart`
  barrel export and the two `SessionEndHooks.run()` calls in
  `user_repository.dart` all landed in the Restore Credentials change without
  a manifest version bump, so no shell ever refetched them — every consumer
  stayed on the cached 1.3.1 tree, which has none of those files. auth_sdk's
  `auth_restore_credential_gate` boot hook, which composes
  `SessionEndHooks.register('restore_credentials', RestoreCredentialGate.clear)`
  into every host `main.dart`, then referenced a class that was not in the
  composed sources: `Error: Undefined name 'SessionEndHooks'` broke the
  paas_driver and paas_manager Android builds. The bump also restores the
  logout/delete-account half of the feature — without the refetched
  `user_repository.dart` nothing ever fires the registered hooks. No source
  change.

## 1.3.0

* New guided-tour fragment `templates/tour/users.tour.yaml` (fragment name
  `users`, per the fleet naming registry): a three-step account chapter —
  the signed-in account surface at `/profile` (tolerant `onFailure`
  navigation for compositions that keep the account surface elsewhere),
  the edit-profile sheet opened via the `TrKeys.profileSettings` tile
  (finder-guarded), and an action-only cleanup step that closes the sheet.
  Brand-neutral: finders go through `AppHelpers.getTranslation(TrKeys.*)`
  and captions use `{app_name}` placeholders, mirroring auth_sdk's
  `auth.tour.yaml`. Additive only — no installs, routes, or lib changes.

## 1.2.1

* Freezed 3 follow-through for the installed profile template (the fleet
  migration covered `lib/src` only): `profile_notifier.dart` now imports
  `package:base_sdk/src/handlers/api_result.dart` directly so its
  `ApiResult.when` call sites resolve against freezed-3 base_sdk
  (`ProfileState` was already `abstract`). No behavior change.

## 1.1.1

* API path fix: every call string in `user_repository.dart` (profile,
  addresses, logout, wallet history, device token, delete-account,
  profile image, password, search) and `address_repository.dart`
  (list/create/delete address) now uses the composed backend's registered
  alias form `paas.api.user.<fn>` (the keys in
  `users/frappe/manifest.json` `hooks.whitelisted_methods`) instead of
  the one-segment-longer `paas.api.user.user.<fn>`, which is not a
  registered name and made every one of these calls a silent 404 on
  composed backends. Client-side only — no alias or backend changes.
* `get_referral_details` and `set_active_address` have no backend
  endpoint at all yet; their paths are normalized to the same convention
  but the calls remain unimplemented server-side until a backend lands.

## 0.0.1

* TODO: Describe initial release.
