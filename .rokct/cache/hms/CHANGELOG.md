## 1.1.0

* feat(hms): incoming Huawei Push Kit messages now show. The token was
  registered, but nothing listened for messages, so a GMS-free device
  received pushes that never appeared. `HmsPushBootstrap.initialize` now
  also listens on `Push.onMessageReceivedStream` and registers
  `hmsBackgroundMessageHandler` as Push Kit's background handler. New
  `HmsPushMessages` raises a local notification (Push Kit's own
  `Push.localNotification`, channel `general_notifications` like comms_sdk's
  `LocalNotifications.show`) for any message with a title or body, and in
  the foreground hands the data to base_sdk `PushMessages`, as comms_sdk's
  `PushMessageDispatcher` does for FCM. Fail-open throughout.

## 1.0.2

* fix(hms): the Huawei push token reaches the backend after sign-in. The
  boot hook sent it before anyone had signed in (so the backend refused it)
  and then treated it as sent, so it was never sent again. Now it only
  counts as sent when the backend accepts it; it is sent again after every
  sign-in (base_sdk `SessionStartHooks`, id `hms_push_token_sync`), and an
  unsent token is retried the next time the app comes to the foreground
  while signed in.
* pubspec version now matches manifest.json (pubspec said 1.0.0).
