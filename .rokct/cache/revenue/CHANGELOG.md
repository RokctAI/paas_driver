## 1.5.0

* Floating-nav back conversion (approved design strip section 12, "no
  double back buttons" — base_sdk 1.39.0 / core#125): the driver and
  manager income template pages replace their standalone `PopButton`
  with the shared `FloatingBottomNav` carrying only the leading back
  segment — one back per screen. The driver page's withdraw button
  rides in the same bottom overlay, above the pill. Back-only (empty
  tab list): the driver app composes no root tab set, and the manager
  template's pushed route cannot reach its host app's root tabs from
  this SDK.
