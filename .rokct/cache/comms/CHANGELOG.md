# Changelog

## 1.7.1

* Freezed 3 follow-through for the installed notification template (the fleet
  migration covered `lib/src` only): `NotificationState` migrated to the
  `abstract class` form and `notification_notifier.dart` given the direct
  `package:base_sdk/src/handlers/api_result.dart` import that brings the
  legacy `when`/`map` extensions into scope. No behavior change.

## 0.0.1

* TODO: Describe initial release.
