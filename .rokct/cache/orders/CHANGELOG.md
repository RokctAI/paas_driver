## 1.5.1

* Fix the manager shipping address page template (composes to
  `lib/presentation/pages/create_order/shipping/shipping_address_page.dart`):
  the six `IntlPhoneField` underline borders referenced the legacy `Style`
  class inside `const BorderSide(...)`, breaking the paas_manager APK build
  ("Not a constant expression", Build (Smart) run 31698905702). Renamed to
  base_sdk's `AppStyle.differBorderColor` and dropped `const` from the
  affected `BorderSide`s, matching the zones#16 courier de-const pattern.

## 0.0.1

* TODO: Describe initial release.
