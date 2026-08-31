# Changelog

## 1.53.0

* `PlaneSpan` grows a fourth claim, `twoIfSpare`: **one plane, and a
  second one only if it would otherwise sit empty**. Every existing
  claim demands a plane count up front — `one`, `two`, `all` — so a page
  wanting a second plane had to take it from the flow beneath. This one
  asks for one plane like any default page and is then GRANTED a
  leftover by `PlaneHost`, out of what would have been the empty stage.
  A page beneath is never displaced to arrange it.
  * `PlaneSpan.claimFor` returns 1 for the new claim — it is the claim
    the page MAKES. The new `PlaneSpan.growthCapFor` returns the most it
    can ever hold (two), and is identical to `claimFor` for every claim
    that does not grow, so nothing about `one` / `two` / `all` changes.
  * `PlaneHost` allocates the active page's claim, serves the earlier
    pages by their own claims exactly as before, and only then lets a
    growing claim absorb what is still unallocated, capped at two. On a
    three-plane screen with one page beneath, that is `earlier | active
    active`; on a two-plane screen, `earlier | active` — the earlier
    page keeps its plane either way.
  * `allowNeighbors: false` now clamps the visible planes to the growth
    cap rather than the bare claim, and a page that refuses neighbours
    is given none (previously the clamp made the two identical, so this
    is only reachable through a growing claim).
  * The motivating adopter is lms_sdk's lesson session (frame 52): the
    board and the attendees panel are two halves of one page, and the
    schedule beneath must keep its plane at two planes while the third
    plane, at three, becomes the attendees half instead of empty space.
  * 6 new tests in `planes_test.dart` cover the claim at one, two and
    three planes, a full flow beneath leaving nothing spare, the page
    alone (grows to two, never to all), and the no-neighbours clamp.
    Package suite: 206 passing, 0 failing (200 before), verified against
    Flutter 3.47.2 / Dart 3.13.2.

## 1.51.0

* REGRESSION FIX: `main` did not compile after 1.49.0 (core#137), which
  took 7 test files down with it. 1.49.0's tests were written but never
  executed — no Dart/Flutter toolchain was available when it was authored
  — so two compile errors shipped. This release only repairs them; no
  memory-pressure or paging behaviour changes. Version note: 1.49.0 is
  on `main` and core#138 declares 1.50.0, so this takes the next free
  number above both.
  * `services/memory_pressure_service.dart` did not import
    `package:flutter/services.dart`. Its import comment asserted that
    `package:flutter/widgets.dart` "re-exports painting.dart and
    services.dart in full"; widgets.dart exports `src/widgets/*` only,
    so `MethodChannel` and `MissingPluginException` were both undefined
    and the library failed to compile:
    `Error: Type 'MethodChannel' not found.` Because `base_sdk.dart`
    exports the service, every test importing the barrel went down with
    it — `app_usage_badge`, `base_wallet_card`, `floating_nav_back`,
    `money_keypad` and `theme_mode_sync` — plus `memory_budget`, which
    imports the file directly. The import is added and the comment
    corrected to say what widgets.dart actually exports.
  * `test/sync_engine_paging_test.dart` imported `package:drift/drift.dart`
    unfiltered alongside `flutter_test`. drift exports `isNull` and
    `isNotNull` as SQL expression builders, which collide with matcher's
    identically-named ones that `expect` needs:
    `Error: 'isNotNull' is imported from both ...`. The test was wrong,
    not the paging code — it asserts real behaviour and now runs. drift's
    two names are hidden at the import; neither is used in the file.
  * Both new suites from 1.49.0 now actually execute: 9 `budgetFor` tier
    tests and 12 outbox paging tests. The package suite is 194 passing,
    0 failing, verified against Flutter 3.38.5 / Dart 3.10.4.

## 1.50.0

* `SavedCardModel` DROPS its `token` field. `Saved Card.token` is the
  gateway reuse credential — presenting it to the gateway charges that
  card again — and pay made it a Frappe `Password` field, so
  `get_saved_cards` and `tokenize_card` stopped returning it. The field
  was therefore always-empty from the moment that landed, and an
  always-empty credential field is how a caller silently sends nothing
  and gets a refused charge. Removing it makes the compiler catch that
  instead: every consumer of `card.token` in the fleet now fails to
  build until it is pointed at `card.id`.
  * REQUIRES pay's saved-card confinement (pay#46) on the backend. The
    charge endpoints key on the Saved Card docname; a client that still
    sends a credential is refused WITHOUT being charged, so the failure
    mode is a saved-card payment that stops working, never a wrong
    charge.
  * `fromJson` now reads the docname from `name` as well as `id`
    (`json['id'] ?? json['name']`). `get_saved_cards` and `tokenize_card`
    name it `name`; without the fallback `id` came back empty and every
    charge keyed on it was refused. Callers that already normalise to
    `id` are unaffected — `id` still wins.
  * `toJson`, `copyWith` and `toString` lose `token` with it. `toString`
    used to interpolate the credential, so a card printed into a log
    carried it there too.
  * `PaymentsRepositoryFacade.processTokenPayment` and
    `WalletRepositoryFacade.walletTopUp` keep their parameter names for
    source compatibility with the shipped implementations, but both are
    documented for what they now carry: the Saved Card docname, i.e.
    `SavedCardModel.id`. No signature changed, so no implementation
    needs touching for this.

* comms (whatsapp): the card checkout no longer reads
  `Saved Card.token`. The button payload already encoded the docname as
  `card_<name>`, so the lookup that turned it back into a credential was
  overhead before the change and returns a mask after it. The docname is
  passed straight to `process_token_payment(saved_card=...)` and the
  lookup is deleted. Fail-closed is preserved and moves server-side: an
  unknown card, or another user's card, refuses before any gateway call
  rather than being reported as paid.
  * New standalone suite
    `comms/frappe/tests/test_whatsapp_saved_card_charge.py` (6 tests;
    3 fail against the pre-change checkout). Needs Python 3.12+ —
    checkout.py contains a PEP 701 multi-line f-string.

## 1.49.0

* ANDROID PLAY QUALITY + RESTORE CREDENTIALS (the 2026-08-26 Play quality
  requirements). Nothing in the fleet reacted to memory pressure, three
  code paths read whole tables into memory, and there was no Restore
  Credentials plumbing. Version note: 1.47.0 landed on `main` with
  core#135 and 1.48.0 with core#136, so this work takes the next free
  number above both.
  * New `services/memory_pressure_service.dart` (exported):
    `MemoryPressureService` sizes Flutter's image cache from the device's
    actual RAM (32MB/200 images below 3GB, 48MB/300 to 4.5GB, 72MB/400 to
    7GB, 96MB/500 above; an unreadable figure falls back to the 4GB tier)
    over a small `DeviceMemoryBridge` method channel, and acts as the one
    registry other SDKs add handlers to — `MemoryEvent.pressure`,
    `.background`, `.resume` — instead of each wiring its own lifecycle
    observer. It evicts the image cache (including `clearLiveImages()`)
    on pressure and on backgrounding, and releases the retained preload
    `WebViewController` on background, re-warming it on the next
    foreground; a controller a `WebViewPage` has adopted is never
    touched. Started from `BaseSdkDependencies.register` and
    exception-guarded end to end: a memory optimisation must never be
    what stops an app booting. Every tier sits at or under Flutter's
    fixed 100MB default, so this can only lower the ceiling.
  * BOUNDED READS. `SyncEngine`'s outbox drain and its temp-id rewrite
    pass, and `AppDatabase.getAll`, no longer materialise whole tables.
    Keyset paging on the immutable `(createdAt, id)` key rather than
    `OFFSET`, because rows change status and are deleted mid-pass. The
    dependency check looks up only the ids the current page declares,
    selecting the id column alone. Bounding each page to rows created at
    or before the pass start reproduces the old single-SELECT snapshot
    boundary. Oldest-first ordering, `dependsOn` gating and the
    `enqueueOrReplace` idempotency contract are unchanged; `getPage`,
    `getAllPaged` and `countBox` are additive and `getAll` keeps its
    contract. One honest difference: the temp-id rewrite now reaches ops
    later in the same pass instead of waiting for the next `kick()`.
  * New `AppDatabase.releaseMemory()` — `PRAGMA shrink_memory`, wired
    into the same background/pressure path. The drift connection is
    deliberately NOT closed on background: `AppDatabase` is a
    process-wide singleton other SDKs hold directly, and `kick()` has no
    awaitable quiesce, so a half-closed database would be worse than an
    open one.
  * New `services/restore_credential_service.dart` (exported) — the
    client half of Restore Credentials over channel
    `rokct.base_sdk/restore_credentials`: `isSupported`, `create`,
    `retrieve`, `clear`, `consumeRestoreSignal`, plus
    `createRestoreKey`/`getRestoreKey`/`clearRestoreKey` carrying
    auth_sdk's `RestoreCredentialPlatform` signatures. Safe on every
    platform — non-Android, Android below 9 and a shell that has not
    registered the channel all return `unsupported` rather than throwing.
    `requestJson` is passed through untouched. Nothing is wired into
    login, register or logout; that is auth_sdk's side.
  * Android template (new shells only — the installer never overwrites an
    existing host file): `targetSdkVersion` 35 to 36; the release build
    switches to `proguard-android-optimize.txt` and the broad keeps gain
    `allowoptimization`, which preserves every kept name while letting R8
    optimize method bodies; new `res/xml/data_extraction_rules.xml` and
    `res/xml/backup_rules.xml` exclude the sqlite database and its
    WAL/SHM/journal siblings, the Flutter SharedPreferences file and the
    `flutter_secure_storage` prefs and key-storage files from BOTH cloud
    backup and device transfer, closing a live credential-exposure path;
    `androidx.credentials` 1.5.0 declared explicitly; new
    `RestoreCredentialBridge.kt` (with the native `E2eeUnavailable`
    retry) and `RokctBackupAgent.kt`, whose `android:backupAgent` is
    paired with `android:fullBackupOnly="true"` — they must stay
    together, or the app falls back to key-value backup and both XML rule
    files are ignored.
  * Tests: `sync_engine_paging_test.dart`, `kv_store_paging_test.dart`,
    `memory_budget_test.dart` — drain ordering across pages, `dependsOn`
    gating within and across pages, the backoff window, retryable
    handling, the temp-id rewrite beyond the first page, the dedupe
    contract, the key/value paging primitives and the cache tier
    boundaries.

## 1.48.0

* THE SPLASH CAN NO LONGER BE A DEAD END. Every consumer app boots through
  `SplashPage`, and every route it hands the screen to is a method some
  installed SDK has to declare — a composition that declares none threw a
  `StateError` out of the host's `_HostAppRoutes.noSuchMethod`, from inside
  an un-awaited `getToken` call where nothing caught it. The app removed
  the native splash and then sat on the splash artwork with no error, no
  telemetry and no way forward. Behaviour is unchanged for every app whose
  routes do resolve; what changes is what happens when one does not.
  * `getToken` is now AWAITED: a navigation failure reaches the existing
    catch instead of vanishing into an orphan future.
  * New `_leaveSplash` wraps every hand-off. On failure the cause goes to
    the one telemetry door (`TelemetryClient.logError`, gateway cmd
    `tenant.api.log_frontend_error`) as `splash_navigation_failed` with the
    destination, the verbatim error and whether a `BASE_URL` was compiled
    in at all, and the boot falls back to the no-connection page, then to
    an in-place stand-in (app name, one friendly translated line, Try
    again). Per the standing error-surface rule the screen gets the
    friendly line only — never the diagnostic detail.
  * A backend the `api_status` probe already reported DOWN no longer gets
    asked for translations. That request could not succeed and cost up to
    two 30s dio timeouts (the repository retries under the control-role
    cmd), so an app with no backend behind it sat on the splash for up to a
    minute before starting from exactly the local data it already had. The
    skip is reported as `splash_backend_unreachable`.
  * `SplashNotifier.getToken` gained the missing `else`: when
    `connectivityWithDialog` says no, it now calls the caller's
    `goNoInternet` callback. A dialog is not a destination — without this,
    a device that dropped its network between the splash's own check and
    this one invoked no callback at all and the splash stayed up. Callers
    that pass no `goNoInternet` behave exactly as before.
  * Test: `splash_boot_test.dart` — an unreachable backend reaching a real
    screen, the skipped translations fetch, the telemetry/screen split, the
    two missing-route fallbacks, and the notifier's radio-off branch.

## 1.47.0

* Dark-mode fix — `GenericProfilePage`'s sign-out confirmation had an
  INVISIBLE Cancel button on every dark host. `_confirmLogout` raises a
  plain Material `AlertDialog` with no explicit background, so in a dark
  app it renders on the theme's dark dialog surface (#2B2930 under
  `ThemeData(brightness: Brightness.dark)`) — against which the button's
  pinned `AppStyle.black` (#232B2F) label AND outline measure 1.00:1.
  Not "hard to read": the whole control was absent, leaving a sign-out
  confirmation whose only visible button was the one that signs you out.
  Both now ride `AppStyle.textPrimary`, so the outlined Cancel reads in
  both polarities (14.36:1 dark, 17.15:1 light). Affects the manager hub
  and every other dark host of the page.
* Test: `profile_logout_dialog_contrast_test.dart` — opens the real
  confirmation from the page's sign-out button, MEASURES the rendered
  dialog surface rather than assuming it, and holds the Cancel label and
  outline to the WCAG 1.4.3 4.5:1 floor in both polarities. Fails on the
  pre-fix tree at 1 passed / 2 failed.
* `TitleAndIcon`'s pinned `titleColor` default is deliberately unchanged.
  Flipping that shared default to a resolving token would trade this bug
  for its mirror: `ModalWrap` sheets paint `AppStyle.white.withOpacity(0.9)`
  and roughly 90 fleet call sites render `TitleAndIcon` on them, which
  would go white-on-white in dark mode. A dark-surfaced host passes the
  resolving token itself; the fix belongs at the call sites.

## 1.46.0

* THE STANDARD LIST LANGUAGE (approved design strip section 38, Ray
  2026-08-30 12:23Z: "33 list language = STANDARD for all lists"). Frames
  38a-38d draw the approved section-33 list mode on three shipped,
  undesigned manager list screens (order history, notifications, sync
  issues); approving them approves the LANGUAGE, not just those screens.
  Its consumers sit in three feature SDKs across two repos and a feature
  SDK may only import `base_sdk` (ADR-005), so the language lives here.
  * New `presentation/components/lists/list_language.dart` (exported):
    `ListFilterTabBar` + `ListFilterTab` + `ListTabCountPill` — the
    colour-coded tab row with per-tab count pills and the tinted-fill
    active treatment (chips 362/363, the 33b treatment expressed over an
    SDK-neutral tab model); `ListCountPill` — the list-header count pill,
    the standard slot on every list (chip 700); `ListRoundAction` — the
    33a header utility disc; `ListScreenHeader` — title + count pill +
    round utilities, with the optional needs-attention hint line (chip
    711); `ListViewMore` — the "View more · +N" paging foot (chip 356).
  * New `presentation/components/lists/list_plane_flow.dart` (exported):
    `ListPlaneFlow` / `ListDetailFlow<T>` — the section-38 plane shape.
    The list DECLARES TWO planes; a tapped row's detail is a pushed page
    with the DEFAULT one-plane claim, so it lands in the LAST plane (the
    12:02Z SHEET FORK — at plane widths the shipped bottom sheet becomes
    a pane) and the nav folds to the corner back pill at the bottom-END
    (chip 347, the 12:36Z two-state nav rule); alone at a three-plane
    width the leftover plane TRAILS BARE (Ray 10:47Z) instead of the list
    stretching. `ListPlaneColumns` lays a list body out in exactly its
    granted planes' worth of columns, collapsing to one on a phone (38d).
  * Test: `list_language_test.dart` — the tab bar's counts/active
    treatment/tap reporting, View-more's appear-and-page rule, the
    two-plane declaration, the last-plane detail claim, the corner pill's
    pop-and-restore, and the plane-aligned columns in both folds.

## 1.45.0

* The shared edit-own-details sheet (approved frame 4d, 2026-08-30 —
  chips 725-734): marketplace_sdk's shipped customer `EditProfileScreen`
  (edit_profile_page.dart, 381 lines, base_sdk imports only) is PROMOTED
  here as `src/presentation/pages/profile/edit_profile_sheet.dart`, so
  every host of `GenericProfilePage` can wire the user-card edit pencil
  (chip 109, `ProfileSectionRegistry.I.onEditProfile`) to the one
  shipped flow — the immediate consumer is merchants_sdk's manager hub,
  whose user card had NO edit-own-details path (the PR #80 chip-243 move
  exposed the gap Ray reported). Field list is the shipped screen's,
  verbatim: drag handle, "Profile settings" title, avatar with the
  photo-change pencil, EMAIL (read-only once valid), FIRSTNAME |
  SURNAME, PHONE NUMBER (read-only, phone-verify flow), DATE OF BIRTH
  picker, GENDER dropdown, Save. The save path was already base_sdk's
  own (`editProfileProvider` -> `UserRepositoryFacade.editProfile` ->
  the self-scoped `update_user_profile` endpoint) — NO backend change.
  Promotion adaptations only: the light-only bgGrey@96% chrome resolves
  the dark surface via `AppStyle.isDark` (the 4d dark render), and the
  photo-pencil glyph moves to base_sdk's `remixicon`
  (`Remix.pencil_line`, unchanged glyph) with explicit ink so it reads
  on its white disc in both modes.
* Test: `edit_profile_sheet_test.dart` — the sheet renders the shipped
  field set from `profileProvider`'s user, and Save drives
  `EditProfileNotifier` end to end into `UserRepositoryFacade
  .editProfile` (recording fake repository; stubbed connectivity).

## 1.44.0

* THE KEY PAD (design chip 390) as a SHARED component — approved on
  frame 11u (tablet checkout, 2026-08-29 15:41Z) and frame 11y (phone
  fold, 2026-08-30 11:27Z); Ray's standing direction makes it the
  standard money-entry surface fleet-wide, so it lives here in the
  package every app composes (the TelemetryClient precedent).
  * New `MoneyKeypad` (`presentation/components/keypad/money_keypad.dart`,
    exported): the 11u/11y pad — 1–9 / 00 / 0 / ⌫ digits grid (the `00`
    money key carried from the paas_pos tender pad) plus the optional
    `.` | OK confirm row. A pure input surface: emits key events, owns
    no text, focuses nothing — the OS keyboard can never appear behind
    it. `MoneyEntry` carries the shared append/backspace/decimal money
    string rules so every adopter edits identically.
  * New `KeySound` service (`services/key_sound.dart`, exported): the
    paas_pos tender-pad sound recipe — `tap()` on EVERY keypress plays
    `assets/audio/tap.wav` (Ray's own paas_pos asset, copied verbatim)
    through a round-robin pool of 5 audioplayers `AudioPlayer`s (rapid
    keying never truncates a click) with `HapticFeedback.lightImpact`
    as the mobile complement; `error()` plays `wrong.wav` (paas_pos's
    insufficient-tender buzz) with a medium haptic. Both behind ONE
    persisted on/off gate, DEFAULT ON
    (`LocalStorage.get/setKeypadSound`, `StorageKeys.keyKeypadSound` —
    paas_pos `AppConstants.sound` parity). Fails open everywhere: no
    asset, no plugin, test binding — silence, never an exception.
  * Assets: `templates/assets/audio/tap.wav` + `wrong.wav` registered
    in `app_assets` and the host pubspec template's asset dirs gains
    `assets/audio/`; new direct dependency `audioplayers: ^6.5.1` (the
    templates/comms constraint rail).

## 1.43.0

* The approved 4c ruling ("will just let profile take two plane max.
  back be on the right"):
  * `GenericProfilePage` self-spread caps at TWO planes, UNIVERSALLY:
    the cap lives in the page itself, so every host of the generic
    profile (customer, merchant, lms, ...) is bound by it — no
    `PlanePage` declaration can spread the profile to three columns.
    Declare the profile's page as `PlaneSpan.two` (never `all`) so at a
    three-plane width the third plane follows the normal plane rules —
    a bare stage or a flow neighbor. Two-plane and phone layouts
    unchanged.
  * The plane layout's back pill moves from the bottom-START corner to
    the BOTTOM-END corner — the right corner in LTR, still directional
    (leads left in RTL), same 16-logical inset inside the SafeArea.
    Pop semantics unchanged: the pill pops the flow's newest step.

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

