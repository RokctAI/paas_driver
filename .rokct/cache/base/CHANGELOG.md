# Changelog

## 1.38.0

* Real dark-mode wiring for the composed app shell ("all sdks should have
  darkmode"). The installed `app_widget.dart` template now builds a genuine
  `darkTheme:` from the AppStyle dark palette (new polarity-pinned
  `AppStyle.surfaceDarkRaw`/`surfaceLightRaw` getters, which track
  `injectBrandColors` but never flip with the current mode), making the
  existing `themeMode:` line live instead of inert. `AppNotifier` now calls
  `AppStyle.setBrightness` when it reads the persisted preference at startup
  and on every `changeTheme`, so the AppStyle-driven surfaces and the
  Material tree agree from the first frame (previously `AppStyle.isDark`
  stayed at its dark-first default on cold start regardless of the stored
  preference). New `AppTheme.defaultDarkMode` static seam (kernel default:
  light) — consulted by `LocalStorage.getAppThemeMode()` only when no
  preference is stored, so dark-first apps (driver, manager) set it `true`
  in app glue before `runApp` to keep their current look; the user's
  explicit choice always wins thereafter.
* All `AppStyle` font helpers (`interBold`/`interSemi`/`interNoSemi`/
  `interNormal`/`interRegular`, `logoFont*`, `logoMotto*`) now default
  `color:` to the mode-resolving `AppStyle.textPrimary` instead of the fixed
  `AppStyle.black` — the ~929 fleet call sites that omit `color:` were
  near-invisible on dark surfaces. Call sites that pass a color explicitly
  are untouched (the parameter is now nullable; a passed value always wins).

