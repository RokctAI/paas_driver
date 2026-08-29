# Changelog

## 1.42.0

* The plane mechanism (the approved plane proposal, frame 1c, plus the
  approved yield/back interaction ruling). New
  `presentation/adaptive/planes.dart`:
  * `PlaneHost` divides a wide window into 1 / 2 / 3 EQUAL-WIDTH planes
    by real logical width on the shared `AppBreakpoints` thresholds
    (< 600 one, 600..839 two, >= 840 three) and windows the user flow
    (`stack`, root first, last entry active) onto them — the deepest
    step always in the LAST plane.
  * `PlanePage` declares its claim in planes (`PlaneSpan.one` — the
    default — `two`, or `all`) and whether earlier pages may sit beside
    it (`allowNeighbors`; false presents the claim alone). Claims are
    never demoted while planes exist; a claim >= the screen's count is
    the full screen; a one-plane screen is the phone layout by
    construction.
  * Importance is dynamic: the ACTIVE page's claim wins, and earlier
    pages YIELD BY COMPRESSING — the page under the active step keeps
    the remaining planes up to its own claim and re-spreads onto them,
    the next outward after that, the rest slide off. BACK pops the
    newest step and the planes return (back restores).
  * `Planes.of(context)` — inherited `.count`/`.index`/`.span` (plus
    `planeWidth`/`gap`/`isLast`) so any page can subscribe and re-flow
    on allocation changes, no polling.
  * The plane layout's back control: `PlaneHost.back` parks the new
    `FloatingBackPill` (the approved `FloatingNavBack` segment in the
    pill's own housing, placement-free) at the BOTTOM-START CORNER —
    directional, so it trails right in RTL; 16 logical in from both
    edges — whenever the flow is deeper than its root (the approved
    ruling: "back button should always be at a corner"). Tapping it
    pops the NEWEST step of the flow — the last plane's content —
    never a spread earlier page. One back per screen: apps whose
    floating nav bar already carries the back segment pass null.
* `GenericProfilePage` self-spread (approved frames 1c and 1f): granted
  planes by a `PlaneHost` above, the page spreads its content across
  them — the registry's ordered sections in balanced contiguous columns
  (three at three planes, two at two), the identity header leading the
  first, the top controls row spanning the full grant, one scroll
  position. Without a `PlaneHost` (or on one plane) the phone list
  renders untouched. Sheets and dialogs never take planes — they
  overlay, exactly as on the phone.
* `AppUsageBadge`'s label now ellipsizes instead of overflowing when
  its surface is narrow (a plane-spread profile column).

## 1.41.0

* Sync drain is now gated on BACKEND availability, not just device
  connectivity. Both automatic `SyncEngine.kick()` triggers — the splash
  boot path and the `ConnectivityService` regain listener — previously
  fired on radio state alone, so a Wi-Fi network without internet (or a
  reachable internet with the tenant backend down) drained the outbox
  into guaranteed failures, burning retry attempts toward the dead cap.
  The splash path reuses the `api_status` probe it already runs
  (`AppConnectivity.backendStatus`) and only kicks when the backend
  answered `up`; the regain listener now confirms
  `AppConnectivity.backendAvailability()` (on-demand check, never
  polled) before kicking. Manual/enqueue-path kicks are unchanged.
  `ConnectivityService` gains test seams (`backendProbe`,
  `onBackendRegained`, `handleConnectivityChange`) and unit coverage
  for the gate.

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

