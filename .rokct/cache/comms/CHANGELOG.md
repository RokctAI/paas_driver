# Changelog

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
