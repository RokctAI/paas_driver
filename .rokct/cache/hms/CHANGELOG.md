## 1.0.2

* fix(hms): the Huawei push token reaches the backend after sign-in. The
  boot hook sent it before anyone had signed in (so the backend refused it)
  and then treated it as sent, so it was never sent again. Now it only
  counts as sent when the backend accepts it; it is sent again after every
  sign-in (base_sdk `SessionStartHooks`, id `hms_push_token_sync`), and an
  unsent token is retried the next time the app comes to the foreground
  while signed in.
* pubspec version now matches manifest.json (pubspec said 1.0.0).
