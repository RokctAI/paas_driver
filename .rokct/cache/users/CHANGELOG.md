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
