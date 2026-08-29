# Changelog

## 1.40.0

* First application of the approved floating-nav back pattern (design
  strip section 12 "APPROVED", shipped as `FloatingNavBack` in 1.39.0 /
  core#125) to base_sdk's own screens: `UiTypePage` now renders the
  floating nav's back segment as its ONE back affordance when pushed —
  the standalone `PopButton` is gone and the AppBar no longer implies a
  leading arrow, ending that screen's double back. Back-only pill (empty
  tab list): the page belongs to the initial flow and carries no root
  tab set.
* `FloatingBottomNav`: a back-only pill or rail (back passed, tabs and
  trailing both empty — the no-tab-set apps' pushed routes) no longer
  draws the back/tabs hairline; there is nothing to split from. Pills
  with tabs render exactly as before.

## 1.39.0

* Floating nav: tabs mode gains an optional leading BACK segment (the
  approved floating-nav back proposal — design strip section 12, "no
  double back buttons"). New `FloatingNavBack` value on
  `FloatingNavTabsMode.back`: caller-supplied icon + already-translated
  label (base_sdk stays icon-set- and copy-agnostic), `onTap` defaulting
  to `Navigator.maybePop` when null. `FloatingBottomNav` renders it as a
  leading segment — PopButton's exact visual DNA (chevron + 12sp label +
  the 4x24 brand-primary dash) moved inside the pill housing, split from
  the tabs by a hairline, on the tabs' own 45.h row rhythm — and, in a
  tablet-mode side rail, stacked at the rail's start the way the rail's
  tabs are. This is the bar's ONE deliberate navigation exception:
  `trailing` stays "never navigation", and the back segment never takes
  the active indicator. A page that passes `back:` renders no back
  affordance of its own (no floating PopButton, no AppBar leading), so
  exactly one back exists per screen. `back` null — the default — renders
  every existing host exactly as before.

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

