# Changelog

## 1.22.2

* fix(comms): the Languages sheet's Save passes `userInitiated: true` to
  `makeSelectedLang` (base_sdk 1.83.5), so a translations failure after the
  person saves still shows, while the same call made on load stays silent.

## 1.22.1

* fix(comms): the Languages sheet and the notification list (and its order
  pane routes) read their surface and ink from Theme.of(context) at build
  time instead of AppStyle.isDark and its mode statics, so a live dark/light
  switch restyles them.

## 1.22.0

* fix(comms): notification badge count reads `data.count`; the notification
  list sends `start`/`limit` and reads the wrapped rows.
* fix(comms): Help/FAQ calls the public `api.faq.get_faqs`; Terms and Privacy
  send `route` to `api.page.get_page` and read its `translation`.

## 1.21.0

* feat(comms): `PushMessageDispatcher` feeds received FCM messages into
  base_sdk 1.79.0's `PushMessages` by `data['type']`. A new boot hook,
  `comms-push-message-dispatch`, starts it on Android, iOS and macOS.
* Foreground messages and taps that open the app are dispatched at once.
  A message that arrives while the app is suspended or closed reaches
  `firebaseMessagingBackgroundHandler` in a background isolate, where no
  feature SDK has a handler. Its data is queued (newest 20) and replayed
  at start and on every resume.
* Adds `shared_preferences` as a direct dependency (base_sdk's pin).
* Requires base_sdk >= 1.79.0.
* Tests: `test/push_message_dispatcher_test.dart`.

## 1.20.0

* feat(comms): `DeviceLiveActivitySink` passes base_sdk 1.78.0's
  `LiveActivitySnapshot.showProgress` to the device. The Android
  `LiveUpdatesChannel` draws no progress bar when it is false.

## 1.19.0

* feat(comms): `DeviceLiveActivitySink`, the platform half of base_sdk
  1.76.0's `LiveActivities`. A new boot hook, `comms-live-activity-sink`,
  registers it.
  - Android 16: the sink asks the host's `rokct/live_updates` channel for a
    promoted `ProgressStyle`. The Kotlin for that channel is a scaffold in
    `templates/native/android`.
  - Otherwise, and on Android 15 and older, the sink posts an ongoing entry
    on the new "Live updates" channel (default importance). The entry has a
    progress bar, `onlyAlertOnce`, a chronometer countdown and
    `timeoutAfter`. "Stage N of M" and the end time go into the text.
  - iOS: the sink starts an ActivityKit Live Activity through
    `live_activities`, held at 2.4.3 because 2.4.4+ needs
    permission_handler ^12, which paas_driver and supacharge cannot resolve.
    The SwiftUI widget is a scaffold in `templates/native/ios` and needs
    Xcode. The sink skips iOS until `LIVE_ACTIVITY_APP_GROUP` is defined.
* `LocalNotifications.ensureInitialized()` and `LocalNotifications.plugin`.
* Requires base_sdk >= 1.76.0.
* Tests: `test/device_live_activity_sink_test.dart`.

## 1.18.0

* feat(comms): ask for notification permission after a successful sign-in,
  in every app that composes comms_sdk. New `PushPermissionPrompt`, wired by
  the new `comms-push-permission-on-sign-in` boot hook into base_sdk's
  `SessionStartHooks`, which auth_sdk runs once a session is established.
  Skips demo sessions (`DemoSession.demoActive`), and asks at most once per
  install: a LocalStorage flag (`comms.push_permission`) is set once the OS
  was actually asked, so an unsupported platform or a failed request tries
  again at the next sign-in. The prompt itself still goes through
  `PushPermissionService`. Requires base_sdk >= 1.75.0; fires only with
  auth_sdk >= 1.15.0 (older auth_sdk never runs the hooks, so nothing
  changes there).
* Tests: `test/push_permission_prompt_test.dart`.

## 1.17.0

* Demo runs the real `SettingsRepository`. `CommsSdkDependencies` registers it
  directly and registers `assets/demo/comms` with base_sdk's `DemoFixtures`;
  base_sdk 1.73.0's `DemoGatewayInterceptor` answers each cmd it sends from
  `templates/assets/demo/comms/<cmd>.json` (installed to `assets/demo/comms`)
  during a demo session. An unknown cmd fails with `DemoFixtureMissing`.
* Deleted `MockSettingsRepository`, the `DemoSession` flip listener and
  `CommsSdkDependencies.stopFollowingDemoSession`; the fixtures carry the data
  the mock served. Needs base_sdk 1.73.0.

## 1.16.1

* Dark mode: hardcoded light fills and dark ink now follow the active theme
  through AppStyle.surfaceFor/cardFor/inkFor/secondaryInkFor/strokeFor(Theme.of(
  context).brightness), and builds read the theme from Theme.of(context) instead
  of static AppStyle reads. Brand fills, white-on-primary and textGrey are
  unchanged.

## 1.16.0

* Changed: demo repositories follow the runtime demo session (phase 2 of
  "demo login in production", Ray 2026-09-08). `CommsSdkDependencies.register`
  picks `MockSettingsRepository` or `SettingsRepository` from base_sdk's
  `DemoSession.demoActive` - a demo BUILD (`--dart-define=IS_DEMO=true`,
  exactly as before) OR a demo SESSION (a server-marked demo account
  signed in on a real build) - instead of the compile-time constant alone,
  and re-registers the `SettingsRepositoryFacade` singleton when
  `DemoSession.instance` flips: a demo account signing in after boot gets
  the fixtures, a sign-out ending its session gets the real repository
  back. One listener per container however often `register` is called;
  a facade a host wired before this hook is never replaced. The
  currencies and notification repositories have no demo twin and are
  unchanged. Requires base_sdk >= 1.62.0. Test-only
  `stopFollowingDemoSession(getIt)`.
* Tests: `test/comms_di_demo_test.dart` - real repository when the
  session is off, the demo twin after `activate()`, real again after
  `clear()`, the twin from registration when the session is already on,
  a host's own registration untouched across flips.

## 1.15.3

* Fixed: the Languages sheet (`LanguageScreen`) painted a light surface
  regardless of theme. `AppHelpers.showCustomModalBottomSheet` paints the
  sheet route transparent and expects the modal to bring its own surface, so
  the `isDarkMode` flag 1.15.2 started passing from the tour never reached
  the paint - guided tour run 34112448075 still captured a light sheet over
  a dark Kitchen page (`16-comms_language.png`). The sheet now resolves
  `AppStyle.isDark ? AppStyle.surfaceDark : AppStyle.bgGrey` (the pair
  base_sdk's `EditProfileScreen` uses) and draws its title in
  `AppStyle.textPrimary`.
* Fixed: the sheet capped itself at 30% of the window height, which on the
  tablet leg (END-anchored narrow panel) pushed the Save button below the
  fold. The cap is gone; the helper's own window-height constraint still
  bounds the sheet and long language lists still scroll.

## 1.15.2

* Fixed: the `comms_language` tour step opened the language sheet with
  `isDarkMode: false`, so the still captured a light sheet inside a tour the
  shells now start dark. The sheet follows `LocalStorage.getAppThemeMode()`,
  the theme the tour is actually running in.

## 1.15.1

* Fixed: privacy policy and terms of service placeholder copy in the mock
  settings repository no longer reads as demo text (rendered by corporate's
  policy page).

## 1.15.0

* `PushPermissionService` — the single guarded entry point for the OS
  notification-permission prompt (`src/common/services/push_permission_service.dart`,
  exported). comms_sdk owns push in every composition, so the guard around
  `FirebaseMessaging.requestPermission` lives here instead of being re-typed
  at each shell's call site.
  * Guided tour run 33476454451 failed both `paas_manager` legs with
    `[firebase_messaging/unknown] A request for permissions is already
    running, please wait for it to finish before doing another request.`
    The tour signs in twice; the second shell mount fired a second
    `requestPermission` while the first was still pending on the OS prompt,
    and the platform channel refused it. The shells did not `await` the
    call, so the exception surfaced as an UNCAUGHT async error that their
    surrounding `try`/`catch` could never see — in `flutter test` that is a
    hard failure.
  * The service carries BOTH halves of the fleet guard idiom already used by
    comms' own `comms-firebase-fcm-boot` hook — the android/iOS/macOS
    platform allowlist (never web; Windows keeps the
    `DesktopNotificationPoller` path) and the fail-open `try`/`catch` that
    `debugPrint`s the detail instead of propagating.
  * On top of that it de-duplicates IN-FLIGHT requests: a concurrent caller
    joins the pending request instead of starting a second one. The first
    request is never suppressed — a single sign-in on a real device behaves
    exactly as it did before, and Android notification permissions are not
    silently disabled for anyone.
  * Pending state is cleared in a `finally`, so a denied, failed or
    synchronously-throwing request cannot latch the guard and leave
    notifications permanently un-requestable for the rest of the process.
  * Purely additive: no manifest key, `cmd`, payload shape or existing Dart
    API changed, so every composed shell keeps compiling untouched. Shells
    adopt it by swapping their raw `FirebaseMessaging.instance.requestPermission`
    call for `PushPermissionService.request()`.

## 1.13.0

* The manager NOTIFICATION LIST adopts the standard list language
  (approved design strip frame 38b, Ray 2026-08-30 12:23Z: "33 list
  language = STANDARD for all lists ... the All/Unread tabs are IN").
  The shipped page was an undesigned white `ListView` whose only
  read-state affordance was the per-row dot, with "Read all" riding a
  bottom overlay ABOVE the floating nav — a placement that collides with
  the two-state nav's corner back pill.
  * New `src/common/presentation/notifications/notification_list_language.dart`
    (exported): `NotificationReadFilter` — the All/Unread read-state
    filter (chip 707, the genuinely new affordance Ray ruled IN), whose
    Unread arm is exactly the shipped dot's condition (`readAt == null`);
    `NotificationRow` — the shipped row verbatim in the dark list dress
    (44 avatar or a tinted glyph for blog/system items, the client as
    "First L.", the body, the Jiffy `fromNow` time) with the shipped
    unread dot, read rows dimming to secondary (chips 704/705);
    `NotificationReadAllAction` — Read all as a HEADER action (chip 706).
  * The installed `notification_list_page.dart` is rebuilt on those
    pieces plus base_sdk's list language: header count pill "N unread"
    (700), the filter tabs, rows in plane-aligned columns, and the corner
    back pill (347 — the shipped pill sat bottom-CENTRE). The list
    declares TWO planes; a tapped notification's order detail lands in
    the LAST plane as a pane, and on one plane it stays the shipped
    bottom sheet.
  * `jiffy` joins the dependencies (the row now formats its own relative
    time inside the SDK).
  * Requires base_sdk >= 1.46.0 (the list language).
  * Test: `notification_list_language_test.dart` — the read-state split
    and its per-tab counts, the "First L." name shape, the unread dot's
    two states, and the tinted glyph fallback.

## 1.12.0

* Floating-nav back conversion (approved design strip section 12, "no
  double back buttons" — base_sdk 1.39.0 / core#125): `SettingPage` and
  the driver/manager `notification_list_page` templates replace their
  standalone `PopButton` with the shared `FloatingBottomNav` carrying
  only the leading back segment — one back per screen. The notification
  pages' read-all button rides in the same bottom overlay, above the
  pill. Back-only (empty tab list) because these pushed routes cannot
  reach their host app's root tab set from this SDK.

## 1.9.0

* Broken-endpoint fix sweep: the notification, settings, and currencies
  repositories now call the backend through base_sdk's universal
  `PlatformGateway` (`api.notification.*`, `api.system.*`,
  `api.admin_content.get_admin_faqs`, `api.page.get_page` cmds — the
  comms/base `manifest.json` whitelisted-method aliases with the
  `{app_name}` segment dropped) instead of the previous direct
  `/api/method/paas.api.*` dotted paths, several of which pointed at
  module paths that do not exist in the composed app
  (`paas.api.user.user.*`, `paas.api.system.system.*`, short
  `paas.api.<fn>` names). `get_mobile_translations` is deliberately left
  as a direct call — its alias-key row belongs to the protocol
  lock-regen thread.

## 1.7.1

* Freezed 3 follow-through for the installed notification template (the fleet
  migration covered `lib/src` only): `NotificationState` migrated to the
  `abstract class` form and `notification_notifier.dart` given the direct
  `package:base_sdk/src/handlers/api_result.dart` import that brings the
  legacy `when`/`map` extensions into scope. No behavior change.

## 0.0.1

* TODO: Describe initial release.
