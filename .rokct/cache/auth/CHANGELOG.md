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
