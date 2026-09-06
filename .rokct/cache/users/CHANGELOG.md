## 1.3.6

* `MockUserRepository` reads the demo avatar from base_sdk's
  `DemoImages.avatar` (new in base_sdk 1.60.4) instead of carrying its
  own copy of the inline SVG literal. auth_sdk's `MockAuthRepository` had
  the same literal for the same reason (ADR-005 forbids one importing the
  other, and the kernel had no avatar entry); both now read the one
  constant, so the header can never swap faces between the login user and
  the fetched profile. Requires base_sdk >= 1.60.4 (declared in
  `manifest.json` `_comment_requires`). `test/mock_user_repository_test.dart`
  pins the avatar to the kernel constant.

## 1.3.5

* The demo profile carries a rand wallet. Every demo amount now prints in
  South African rand - base_sdk 1.60.3 seeds its `DemoCurrency` (id `ZAR`,
  symbol `R`, position `before`) at boot after the guided tour's wallet
  history read "42.50USD" / "1,500.00USD" - and the account
  `MockUserRepository` serves is the one surface that still described no
  currency at all. Its `ProfileData` now carries `Wallet(uuid: 'wallet-1',
  price: 793.00, currency: DemoCurrency.rand)`: the balance is the net of
  wallet_sdk's demo ledger (a top-up, two purchases, a partial refund and
  a cash-out on that wallet), so the profile's wallet card ("R793.00") and
  the history page agree. Requires base_sdk >= 1.60.3 (declared in
  `manifest.json` `_comment_requires`). `test/mock_user_repository_test.dart`
  guards the currency, the wallet id and the balance.

## 1.3.4

* Demo builds get a `MockUserRepository`, selected by the same
  `AppConstants.isDemo` ternary in `UsersSdkDependencies.register` that
  already picks `MockAddressRepository`. `UserRepositoryFacade` was the
  HTTP `UserRepository` unconditionally, so in a demo build - no backend -
  every `profileProvider.fetchUser` failed, `LocalStorage.getUser()`
  stayed null (auth_sdk never persists the login user; production relies
  on this fetch) and base_sdk's `GenericProfilePage` fell back to
  "Profile" for the name and an orange "?" avatar, under the failure
  snackbar, in every shell's account still. The mock serves the account
  auth_sdk's `MockAuthRepository` signs in (Thandi Mokoena, `+27 82 456
  7890`, "42 Marula Avenue, Sandton", inline-SVG initials avatar), takes
  email and role from the persisted session when there is one and never
  invents a role otherwise (the sign-in address decides it; merchants'
  `SignedInRoleToast` and orders board read `LocalStorage.getUser()?.role`),
  keeps profile edits and avatar changes in memory for the session, and
  ends the session on logout / delete-account the way the HTTP repository
  does (`SessionEndHooks.run` then `LocalStorage.logout`). auth_sdk's
  post-login `syncFcmToken` now also lands on the mock instead of a
  failing request.
* `MockAddressRepository` no longer seeds "123 Demo St" (San Francisco)
  and "456 Office Blvd": the address book is the same "42 Marula Avenue,
  Sandton" home the profile shows, plus "15 Alice Lane, Sandton" for work.
  `test/mock_user_repository_test.dart` pins the wording and the
  profile/address-book agreement.

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
