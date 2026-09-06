## 1.20.3

* fix(tour): the `driver_available_orders` caption in
  `templates/tour/delivery.tour.yaml` wrapped to eight rows on the phone
  caption canvas, one more than the box holds, so the assembler aborted
  the phone video build on the paas_driver guided tour (run 34055656521:
  `caption for step 'driver_available_orders': 8 rows overrun the caption
  box by 21px (it holds 7)`) and the commit-back then dropped the shell's
  Play listing assets (feature graphic, icon, phone chapter videos, wide
  reel) from main. The caption now wraps to five rows at the assembler's
  geometry (DejaVu Sans Bold 64 px, 936 px wrap width, 84 px row pitch, a
  7-row box) with the same meaning: nearby orders taken with one tap, and
  the launcher's driver window showing the shop, the drop and Accept but
  never the money. Before and after:

  ```text
  Orders ready for pickup near you - *grab the next job* with one tap. On the launcher, the same job is the driver window: the shop, the drop and Accept, never the money.
  Orders ready nearby - *grab the next job* with one tap. On the launcher: the shop, the drop and Accept, never the money.
  ```

  No screen changes. Shells pick the fragment up on their next tour run:
  the composer refreshes the cache copy and captions only reach
  `tour.resolved.json`, never a committed shell file. Every other caption
  in the fragment already wraps to five rows or fewer.
* manifest.json 1.20.2 -> 1.20.3 so version-aware cache reconciliation
  re-merges the fragment into every shell.

## 1.20.2

* Driver home defers creating the Google Maps platform view until the page
  has settled and is the current route, so a page replaced within a second
  of opening (demo sign-in churn) no longer trips the plugin's
  `updateTileOverlays` channel error. The map is wrapped in the new
  `DeferredMapSurface` (`lib/src/driver/presentation/widgets/
  deferred_map_surface.dart`): one frame painted, 800 ms as the current
  route, still mounted - then the `GoogleMap` mounts; a route replaced
  inside that window never spawns the native view (the plugin's own
  un-awaited post-creation calls are what threw, from
  `google_maps_flutter_android/src/messages.g.dart`, so no guard in the
  page could catch them - paas_driver tour 34049256577, phone leg 4/17 on
  both attempts). Until then the map area is a plain surface-coloured box.
  The timer is cancelled on dispose and re-armed when a covered route
  becomes current again. Pinned by `test/deferred_map_surface_test.dart`
  and `test/driver_home_deferred_map_test.dart`. No visible screen change
  beyond the first 800 ms of the home page.
* CHANGELOG: the two bare code fences (the 1.18.2 `cutter.svg` and the
  1.17.4 location-permission log excerpts) now carry a `text` language
  tag. This file is vendored into every shell's
  `.rokct/cache/delivery/CHANGELOG.md`, where markdownlint MD040 is on,
  so `lint / Markdown Lint` was red on every paas_driver PR.

## 1.20.1

* Driver home no longer reads `ref` from its 36 s camera-idle timer after
  the page is disposed (tablet tour crash: `Bad state: Cannot use "ref"
  after the widget was disposed`). Every callback handed to the page's
  `Delayed` helper now bails out with `if (!mounted) return;` first. The
  helper lives in base_sdk (`tpying_delay.dart`) and exposes no cancel, so
  `dispose()` cannot cancel the pending timer; the guard is the fix and
  `dispose()` documents why. Pinned by
  `test/driver_home_delayed_timer_test.dart`. No visible screen change.

## 1.20.0

THE DRIVER WINDOW ON THE LAUNCHER CANVAS - approved design strip frame 53e
(Ray 2026-09-01, "all launcher screens approved"): driver mode, set by the
app the launcher found, carrying one window and no money.

* New `DriverLaunchWindow` (`lib/src/driver/presentation/launcher/
  driver_launch_window.dart`), the content of the launcher's driver window
  (chip 1255): "Order waiting" with the pick-up shop and the drop suburb,
  each with its distance when known (chip 1287), and one Accept that opens
  the driver app on the job; "Job in hand" with an Open for the order the
  driver is already working; "No job right now" with an Open when nothing
  is waiting. The launcher owns the chrome and the placement (53g).
* NO MONEY (chip 1291, ruled): the fee and the cash on hand that the frame
  used to carry are absent, not masked - `DriverLaunchJob` has no fee
  field. NO PERSON (chip 1290, open): the drop is the suburb only
  (`DriverLaunchJob.suburbOf` keeps the last segment of the address), never
  a name, a street or a number.
* DATALESS BACK SEAT (chip 1288, ruled: "data dont show on launcher when
  another mode is active"): `DriverLaunchWindow.dataless` renders the Open
  affordance alone, so the window is useful and tappable without data.
* Data comes through the same facade the driver home reads
  (`CourierOrdersRepositoryFacade`: the current order first, then the first
  available one), which in an IS_DEMO build is the seeded
  `DemoCourierOrdersRepository`; a composition with no facade and no demo
  seed, or a backend that does not answer, renders the no-job state and
  never throws.
* manifest.json 1.19.1 -> 1.20.0: top-level `integrations` inject the
  window under launch_sdk's `// @launcher-windows` marker and its import
  under `// @launcher-windows-imports` (productivity_sdk's glance pattern;
  requires launch_sdk >= 1.4.3, declared in `_comment_requires_launcher`);
  top-level `tr_keys` for the window's copy (`order.waiting`,
  `job.in.hand`, `no.job.right.now`, `pick.up`, `drop`). The mode line and
  the "set from the app found" status (chips 1257, 1283) are the launcher's
  (53k); nothing here names a package.
* Tests: `test/driver_launch_window_test.dart` covers the populated,
  in-hand, no-job and dataless states, the money and person exclusions,
  the loader against the demo seed and against a facade that fails, the
  suburb reduction and the distance derivation, and the manifest wiring.

## 1.19.3

Two more plain bugs in the installed driver home template
(`templates/pages/driver/home/home_page.dart`), no design change.

* **Position stream leaked past the page** (`getCurrentLocation`): the
  on-duty lane's `getPositionStream().listen(...)` subscription was never
  held, so nothing could cancel it — not the duty toggle's OFF path, not
  `dispose`. Every toggle to online stacked one more listener, and each
  kept writing `latLng` and the stored address for the life of the
  isolate, page or no page. The subscription is now held
  (`_positionSub`), starting the lane again cancels the earlier listener
  first, and a shared `_stopTracking()` — the OFF path and `dispose` both
  call it — cancels the poll and the stream together.
* **`IS_DEMO` builds opened on the device's real position** rather than
  the seeded South African address: `_acquireLocation` asked the platform
  for a fix like any other build, wrote it over the stored address and
  animated the map there (an emulator's default Californian coordinate,
  an ocean away from every seeded job), and the on-duty lane did the same
  through its stream. `CourierLocationFix` now carries the gate
  (`pinnedBuild`, `AppConstants.isDemo`): a pinned build never touches
  the platform, `current()` answers with the stored address — else the
  seed's anchor — tagged `CourierLocationResult.pinned` so the page
  leaves storage alone and only moves the camera, and `getCurrentLocation`
  starts the routing poll but not the platform lane. The gate is
  injectable (`CourierLocationFix(pinned: ...)`) and unit-tested; nothing
  changes for a build without `IS_DEMO`.
* **Manifest**: 1.19.1 -> 1.19.3 (1.19.2 is the driver_profile tour-still
  release).

## 1.19.2

Tour: driver_profile step no longer captures a still; the users fragment's
users_profile owns the /profile still when both fragments are chained
(paas_driver run 33952132288 duplicate-still gate).

* `templates/tour/delivery.tour.yaml`: `driver_profile` keeps its
  `action: route` to /profile (the courier chapter still ends on the
  profile page) but is now `screenshot: false`. In paas_driver both the
  delivery and users fragments photograph /profile, and the assembler's
  duplicate-still gate (shared-workflows #486) fails the run when two
  captures are byte-identical (`driver_profile == users_profile`). The
  users fragment's still is load-bearing for other shells, so the
  delivery side yields.

## 1.19.1

Two crashes that stopped the paas_driver guided tour on the driver home
page (run 33911125552; phone leg 4/18 stills, tablet leg 6/18). Both are
plain bugs in the installed home template, no design change.

* **Map camera after the page is gone** (`_acquireLocation` /
  `_moveCamera`, `templates/pages/driver/home/home_page.dart`): the tour
  signs the demo courier in (landing on /home), walks the auth screens and
  routes to /home again, so the first HomePage is disposed with its
  location request still in flight. When the fix landed, the
  `GoogleMapController` it kept was non-null but its platform view was
  already torn down, and `animateCamera` threw
  `PlatformException(channel-error, ...MapsApi.animateCamera)` out of an
  un-awaited future, ending the test. The camera move now checks
  `mounted`, requires a controller, and catches `PlatformException`;
  `dispose` drops the controller reference.
* **Routing poll after dispose** (`getSetProgressLocation`): the
  10-second `Timer.periodic` started once the courier is online was only
  cancelled by the duty toggle's OFF path, never by leaving the page, so
  it fired `ref.read` on a disposed element ten seconds after the tour had
  routed on to /orders (`Bad state: Cannot use "ref" after the widget was
  disposed`). The page now cancels it in `dispose`, the callback returns
  (and cancels itself) when unmounted, and starting the lane again
  cancels any earlier poll instead of orphaning it.
* **Manifest**: 1.19.0 -> 1.19.1.

## 1.19.0

Design strip section 49, the last piece: **chip 301 — the driver root tab
set** (Home · Jobs · Route · Income · Profile) and **frame 49d's
"TODAY · SHIFT ENDED 17:04" stamp**. Approved by Ray 2026-08-31.

* **Chip 301 — the root tab set** (`DriverRootNav`, `DriverRootTab`,
  `lib/src/driver/presentation/home/driver_root_nav.dart`): the shared
  `FloatingBottomNav` pill, which every other driver page already mounts
  with `tabs: const []` ("the driver app composes no root tab set"), now
  carries a tab set for the first time. The installed home template
  mounts it the way its siblings mount the pill and maps each tab to an
  EXISTING route — Jobs → `OrdersRoute`, Route → `DriverRouteRoute`,
  Income → revenue's `DriverIncomeRoute`, Profile → `ProfileRoute`; Home
  is the page itself. Home is lit while the driver idles (49a/49d/49e)
  and Jobs while he is inside a job (49c). Active mark is the filled
  rectangle, as the frames draw it. No `tabletPlacement`: section 49 is
  phone-only and the nav inherits the fleet default (bottom pill).
* **Removed from home**: the two free-floating left-edge icon buttons
  (order history with a count badge, route) — both are tabs now and the
  frames draw no such buttons. The avatar (→ Profile) and the duty
  toggle stay where the driver's thumb expects them.
* **Sheets clear the pill**: `driverRootNavClearance()` is added to the
  bottom padding of the idle sheet, the job sheet and the parcel sheet
  so the last card / primary action is never buried under the nav.
* **Frame 49d — the SHIFT ENDED stamp** (`shift_stamp.dart`,
  `CourierStorage.setShiftEndedAt` / `getShiftEndedAt`): the frame
  flagged the time as unsourced (`setOnline` stores a bool only) and
  asked for "either a client-side local timestamp or a server field".
  This is the client-side one: the duty toggle's success path records
  the minute the driver went OFF duty beside the flag it already flips,
  and clears it when he comes back; the off-duty day strip (chip 931)
  reads it back as `TODAY · SHIFT ENDED HH:mm`. Never guessed: no stamp,
  or a stamp from an earlier day, and the strip says TODAY.
* **Manifest**: `jobs`, `route` and `shiftEnded` tr_keys (home / income /
  profile are base keys). 1.18.0 → 1.19.0.
* **Tests**: `test/driver_root_nav_test.dart` — five tabs in the drawn
  order, the lit tab follows the state, every tap reports its tab, the
  stamp only ever names today's shift.

## 1.18.2

Version moved to 1.18.2 so it does not collide with zones #94 (1.18.1).

The paas_driver guided tour aborted on every leg right after the driver
sign-in. Run `33783152823` (log lines 2384-2477) died three times on the
courier home with

```text
Unable to load asset: "assets/svg/cutter.svg".
The asset does not exist or has empty data.
#6      SvgLoader._load.<anonymous closure> (package:flutter_svg/src/loaders.dart:153:41)
```

* The courier home renders `SvgPicture.asset("assets/svg/cutter.svg")` in
  `templates/components/driver/orders_item.dart:294`,
  `templates/components/driver/order_item.dart:310` and
  `templates/pages/driver/push_order/push_order_screen.dart:112`, but the
  manifest's `app_assets` listed only `assets/svg/balance.svg` and
  `templates/assets/svg/` carried only `balance.svg`. The installer
  regenerates the shell pubspec's `sdk-app-assets` block from `app_assets`
  alone, so `cutter.svg` never reached the bundle even though paas_driver
  tracks the file at `assets/svg/cutter.svg` (paas_driver #77). In a real
  build the icon is missing; under `flutter_test` the load failure is an
  uncaught assertion and the tour ends there.
* `cutter.svg` is now a custodianship copy in `templates/assets/svg/`
  (byte-identical to paas_driver main), `app_assets` declares
  `assets/svg/cutter.svg`, and `asset_keys` gains `svgCutter` next to
  `svgBalance`. The three templates reference the path literally, so no
  Dart changes; paas_driver's tracked copy survives the already-present
  guard and only the pubspec declaration is new.

## 1.18.1

Ray's rule for demo builds: "demo in text or demo data is not needed". The
driver demo seed (`DemoDeliverySeed`, `--dart-define=IS_DEMO=true`) rendered
"Demo Diner", "Sample Spaza", "1 Placeholder Plaza, Demoville", "Thandi
Demo", "Sipho Example", "Placeholder Pizza (Large)", "DRS-DEMO-0001",
"Demo Motors" / "DEMO 123 GP" and the bank-deposit sheet's "Demo
Operations" / "Demo Bank" on every tour screen. Every rendered string now
reads like real (still invented) South African data; ids, uuids, keys and
handles are unchanged.

* **Shops**: "Corner Kitchen", 42 Marula Avenue, Sandton (the same seller
  the commerce fixtures use) and "Mama Thembi's Spaza", 7 Vilakazi Street,
  Orlando West, Soweto, each with a real-sounding one-line description
  instead of "Fictional demo merchant — not a real business."
* **Customers**: Thandi Nkosi, Sipho Dlamini, Lerato Mahlangu with
  `@rokct.ai` mailboxes instead of `@example.com`; parcel sender/recipient
  names follow.
* **Products**: Sparkling Lemonade 500 ml, Chicken Mayo Sandwich, Orange
  Juice 1 L, Margherita Pizza (Large), Weekly Groceries Box, Breakfast
  Basket, Dinner for Two.
* **Addresses**: 12 Cradock Avenue, Rosebank; 34 Jan Smuts Avenue,
  Rosebank; 56 Rivonia Road, Sandton; 78 Grayston Drive, Sandton (orders,
  parcels and route stop labels all agree).
* **Notes**: "Gate code 1234, call on arrival.", "Signed contracts, keep
  flat.", "Birthday gift, handle with care."; the transaction note is
  "Order payment".
* **Dispatch route**: `DR-0001` / `DRS-0001` (the DEMO segment dropped),
  labels rebuilt from the new names, notes "Morning dispatch route, four
  stops".
* **Courier**: Dumi Khumalo, `dumi.khumalo@rokct.ai`, on a Honda Ace 125
  registered KLM 482 GP.
* **Bank deposit** (`DemoDriverDepositRepository`): beneficiary "Rokct
  Operations" at "Standard Bank". The `DEMO-DEP-*` record ids only ever
  reach widget `Key`s, never text, so they stay.

`test/demo_driver_details_test.dart` follows the vehicle fixture. No Dart
toolchain was available where this change was made, so the tests were
hand-updated and not run.

## 1.18.0

Design strip frames 49g, 49h and 49i — the driver's bank-deposit route.
A driver whose wallet went negative (cash docked at Delivered) can now
pay the tenant back from the app: choose a method, pay into the tenant's
account, photograph the slip, send it for a person to approve, and watch
where it stands. Nothing moves in the wallet until a manager approves —
the balance on every one of these screens is the ledger's word, never
netted against the pending amount. No deadline, due date or "deposit
before your next shift" appears anywhere (nothing in the fleet backs a
deposit obligation).

* **49g — method chooser** (`DepositMethodSheet`,
  `lib/src/driver/presentation/deposit/deposit_method_sheet.dart`): the
  wallet stated as a sentence, then Card (wallet_sdk's `/wallet-topup`,
  pushed by path with an on-failure line because paas_driver composes no
  wallet_sdk) and Bank deposit (inert with a line when the tenant is not
  accepting deposits — chip 975 is read BEFORE the sheet opens).
* **49h — capture** (`BankDepositSheet`, `bank_deposit_sheet.dart`): the
  beneficiary block with the account masked on screen and copied in full
  (chip 975), the amount on chip 390 (MoneyKeypad, prefilled with what he
  owes as a suggestion), the reference generated FOR him from his initials
  and the minute so he can write it on the slip (chip 977), the slip from
  camera or library (chip 976), and Send for approval (978), inert while a
  send is in flight.
* **49i — status plane** (`DriverDepositStatusPlane`,
  `deposit_status_page.dart`, routed as `/driver-deposits` through the
  installed `templates/pages/driver/deposits/deposits_page.dart`;
  `?choose=1` opens the chooser over it): balance head with the
  "unchanged until approved" line while a request is live (971), the live
  request (979), the Submitted · Under review · Approved trail (980), his
  earlier deposits with a refusal's reason under a rejected row (982/981),
  an explainer of why the wait is a person's check, and chip 347's back
  pill.
* **Wiring**: the home wallet card's Top up (chip 970) now opens the
  chooser (`DriverDepositFlow.openChooser`) instead of the income page;
  Open wallet is unchanged.
* **Data**: `DriverDepositRepositoryFacade` / `DriverDepositRepository`
  (`api.wallet.get_deposit_destination`, `api.wallet.submit_deposit_request`,
  `api.wallet.list_deposit_requests`, `api.payment.get_wallet_balance` over
  the platform gateway; the slip goes up through base's multipart gallery
  seam and only its URL rides the envelope), `DemoDriverDepositRepository`
  for the demo compose, `DepositNotifier` / `depositProvider`, and the
  typed rows in `deposit_request.dart`. Registered by
  `DriverDeliveryDependencies.register`.
* Requires the wallet backend that carries `Wallet Deposit Request`
  (RokctAI/pay, `{app_name}.api.wallet.*`); see
  `_comment_requires_deposits` in the manifest. Guarded by
  `test/deposit_repository_gateway_test.dart`,
  `test/deposit_grammar_test.dart` and `test/deposit_screens_test.dart`.

## 1.17.4

Version moved to 1.17.4 so it does not collide with zones #91 (1.17.3).

A driver who has no location permission now gets a working home page
instead of an unhandled `PermissionDeniedException`.

* The driver home page's location handling moves out of the template into
  `CourierLocationFix` / `CourierLocationNotice`
  (`lib/src/driver/infrastructure/services/courier_location_fix.dart`),
  where it can be tested. paas_driver guided tour `33623262696` reached
  `driver_home` and died on it:

  ```text
  The following PermissionDeniedException was thrown running a test:
  User denied permissions to access the device's location.
  #0  GeolocatorAndroid.getCurrentPosition (...:140:7)
  #1  _HomePageState.getMyLocation (.../home/home_page.dart:232:19)
  ```

  Frame #1 is the `else` arm of `getMyLocation()`, the one that runs when
  `check` is not `LocationPermission.denied`. On the boot path `check` was
  still `null` — `initState` fires `checkPermission()` and `getMyLocation()`
  without awaiting either — so `getMyLocation` skipped both denial branches
  and called `getCurrentPosition()` having asked the OS for nothing. Android
  refused the call outright (the tour's logcat carries no
  `GrantPermissionsActivity` and no `ACCESS_*_LOCATION` request against
  `app.juvo.driver` at all) and the exception escaped an un-awaited future,
  where nothing could catch it.
* `CourierLocationFix.current()` never throws. It establishes the permission
  state first and asks once, answers `deniedForever` and `denied` without
  pointlessly calling for a fix, and catches `PermissionDeniedException`,
  `LocationServiceDisabledException` and anything else around
  `getCurrentPosition()` — the platform can refuse the call even when the
  state read said otherwise, which is precisely what the tour's emulator
  did, so no amount of state checking replaces the catch. Every refusal
  comes back as a `CourierLocationResult` carrying the verbatim platform
  text.
* The refusal is reported, never swallowed. `CourierLocationNotice.show()`
  routes it through base_sdk's `ErrorPresenter.showTechnical` — the fleet
  split of decision-log entry 56: the driver sees one friendly translated
  line (`TrKeys.agreeLocation`, the same line base_sdk's `LocationService`
  shows) and the `PermissionDeniedException` text, which is diagnostic
  detail and not copy written for a driver, rides `TelemetryClient` to
  admins. `CourierLocationNotice.report()` is the telemetry-only form for a
  caller whose page is already gone.
* The home page keeps rendering throughout: `latLng` already falls back to
  the last saved address and then the demo pin, so without a fix the map
  simply stays there and the "my location" button remains a way forward.
  The two un-awaited `initState` calls now share one in-flight future, so
  the driver is asked for permission once instead of by two callers racing
  the platform channel, and the camera move became `googleMapController?.`
  — a fix that lands before `onMapCreated` must not throw out of that same
  un-awaited future either.
* The on-duty tracking lane (`getCurrentLocation`) carried the same hazard
  in `.then(...)` and `.listen(...)`; both now route a refusal to telemetry
  and produce nothing, rather than raising an unhandled async error.
* `test/driver_location_permission_test.dart` pins all of it: no refusal at
  any permission state escapes as an exception, a granted fix still comes
  through untouched, the friendly line is what reaches the screen, the
  exception text is what reaches telemetry, and neither swaps places.

## 1.17.3

Version moved to 1.17.3 so it does not collide with zones #90 (1.17.2).

Dart SDK fix-wave 2026-09-02 (frappe + dart halves; Next.js deferred).

* `DeliveryPointsRepository.getDeliveryPoints` (customer nearest pickup
  points) is repointed off the dead direct
  `/api/method/paas.doctype.delivery_point.delivery_point.get_nearest_delivery_points`
  GET (a dotted name registered in no manifest - a silent 404 behind the
  spinner) onto the universal platform gateway as
  `api.delivery.get_nearest_delivery_points`. The alias is added to
  `delivery/frappe/manifest.json` in the same change, targeting the
  existing `Delivery Point` doctype def, so the Dart half stays answered
  by this SDK's own frappe half (merchants' `api.shop` twin would have
  crossed SDK lines). The def gains `allow_guest=True` like its
  `get_delivery_points` / `get_delivery_point` siblings because the
  repository calls with a guest client. `getAllDeliveryPoints` unchanged.
* `CourierParcelRepository.getActiveOrders` / `getHistoryOrders` (driver
  parcel tabs) are repointed off the Laravel-era
  `/api/v1/dashboard/deliveryman/parcel-orders/paginate` GET (no Frappe
  router rule serves that prefix - every tab 404ed) onto the gateway as
  `api.delivery_man.get_deliveryman_parcel_orders` with
  `limit_start` / `limit_page_length`. That def lists the courier's own
  parcels newest first and takes no status or date filter (a server-side
  kwarg is a pending owner decision), so the accepted/ready/on-a-way vs
  delivered split and the history date window are applied client-side
  per fetched page, with a 50-row window so a page of closed parcels
  cannot read as "no active parcels". Rows are `frappe.get_list` dicts
  keyed by docname; the docname is mirrored under `id` for base_sdk's
  `ParcelOrder`.
  * `getAvailableOrders` is deliberately NOT repointed: the only driver
    parcel list on the server filters `deliveryman == session user`, so it
    cannot answer "parcels with no courier yet" - routing it there would
    show the courier's own ready parcels as available, wrong data
    silently. It keeps failing visibly (flag, never delete) until an
    unassigned-parcels def exists. `showParcel` likewise stays: there is
    no driver-scoped single-parcel def (`api.parcel.get_user_parcel_order`
    is customer-scoped). Both are listed in the fix-wave report.
  * `getDeliveryVehicleTypes` (`/api/v1/rest/delivery-vehicle-types`) stays
    as-is: the only server read is admin-gated
    (`api.admin_logistics.get_delivery_vehicle_types`); a driver-readable
    def needs an owner decision.
* Hygiene: the `/* ... */`-commented legacy copy of `BecomeDriverPage`
  (host `package:driver/...` imports, the missing
  `../../../../application/providers.dart`) at the top of
  `lib/src/common/presentation/pages/become_driver/become_driver.dart` is
  removed - the live page below it, and the driver `/become-driver` route
  (which imports the `templates/pages/driver/become_driver/` copy), are
  untouched. The commented-out `_notifications` block in
  `templates/pages/driver/profile/profile_page.dart` that referenced a
  non-existent `ListNotificationRoute` is removed; the live call already
  uses `NotificationListRoute`.
* Tests: `test/delivery_points_repository_test.dart` and
  `test/parcel_repository_gateway_test.dart` pin the cmd, payload keys,
  auth flag, page-to-offset arithmetic and the client-side status/date
  split through a recording `HttpService` double
  (`test/support/recording_http_service.dart`).
  `frappe/tests/test_manifest_whitelist_aliases.py` resolves every tenant
  alias in `delivery/frappe/manifest.json` to a `@frappe.whitelist()`
  def with `ast` (bench-free) and pins the guest flag on the new alias.
* Patch bump: manifest 1.17.1 -> 1.17.3 (1.17.2 is zones #90), pubspec
  1.3.0 -> 1.3.1. (The 1.17.0 / 1.17.1 manifest bumps landed without a
  CHANGELOG heading; see the git log for those two.)

## 1.17.2

* Fix the driver home sheet's layout contract. Every `paas_driver`
  guided-tour run died on the first frame of `driver_home` with
  `BoxConstraints forces an infinite width` — `BoxConstraints(w=Infinity,
  0.0<=h<=Infinity)` — thrown by the `Column` in the installed
  `lib/presentation/pages/home/bottom_sheet_screen.dart`, and the
  cascading `RenderBox was not laid out` on `home_page.dart`'s `Stack`
  took the whole page with it. The run captured 4 of 18 screenshots on
  both the phone and the tablet leg and never reached `TOUR_COMPLETE`.
  * `BottomSheetScreen.build` returns an `AnimatedPositioned` that pins
    `bottom` and nothing else. A `Stack` child positioned on one axis
    only is laid out with `BoxConstraints(unconstrained)`, so the sheet
    has always been horizontally unbounded — survivable while its child
    was a single `Container` asking for `MediaQuery.sizeOf(context)
    .width`, which sizes itself.
  * 1.15.0's weather banner wrapped that container in
    `Column(crossAxisAlignment: CrossAxisAlignment.stretch)`. Stretch
    hands every child `minWidth == maxWidth == constraints.maxWidth`,
    and under an unbounded parent that is `w=Infinity` — a tight
    infinite constraint, which `RenderObject.layout` refuses. The
    banner's `Padding` was simply the first child in line.
  * The fix is `left: 0, right: 0` on the `AnimatedPositioned`: the
    column is now bounded by the stack, which is the width this sheet
    already drew at, so stretch means "as wide as the sheet". No widget
    was removed, no state branch changed, and the sheet renders exactly
    as before.
  * `test/driver_home_sheet_layout_test.dart` pumps the real template as
    a direct `Stack` child under a `Scaffold` body — on duty, off duty
    and tucked away — and fails on any exception, reproducing the tour's
    assert verbatim without the fix.

## 1.16.0

* Fix the driver-role DI hook that was never declared. `paas_driver`'s
  courier home page crashed on its FIRST build with `Bad state: GetIt:
  Object/factory with type CourierOrdersRepositoryFacade is not
  registered inside GetIt.` — every driver build, release and demo
  alike, not just the guided tour.
  * `DriverDeliveryDependencies.register` (`lib/src/driver/di/
    driver_delivery_di.dart`) is what registers the four courier facades
    — `CourierOrdersRepositoryFacade`, `CourierParcelRepositoryFacade`,
    `CourierRepositoryFacade`, `CourierRouteRepositoryFacade` — plus
    `HttpService` and the `CourierStorage` pre-warm. It is deliberately
    kept OUT of the barrel (a customer app's cache has `lib/src/driver/`
    stripped), so the common `DeliverySdkDependencies.register` cannot
    call it; it only ever registers `DeliveryPointsRepositoryFacade`.
  * Before driver migration M4 the host called it from its own tracked
    `dependency_manager.dart`. M4 untracked `lib/` wholesale and carried
    the splash-preserve and workmanager lines across into this manifest's
    `boot_hooks`, but no `di_hooks` entry was ever declared for the
    courier DI — so from M4 onward `register()` simply never ran at boot.
    The only surviving caller was the lazy `isRegistered` fallback inside
    `CourierVehicleDetailsAdapter` in `templates/adapters/driver/
    delivery_adapters.dart`, which fires solely on the post-register
    vehicle-details step and so never covered the home page.
  * The throw is eager, not incidental: `order_provider.dart` builds
    `OrderNotifier(orderRepository)` at provider construction, and the
    home page's default no-active-order branch renders
    `BottomSheetScreen` immediately.
  * The fix is one added `di_hooks` entry in `app_type.driver`
    (`delivery-driver-role-di`, order 10), the exact mirror of
    `revenue_sdk`'s `revenue-driver-role-di`. Direct `src/` import by
    design, like that one; `register()` is `isRegistered`-guarded
    internally, so a hand-wired host that still calls it double-boots
    safely. Order 10 sits ahead of `revenue_sdk`'s 12 and `zones_sdk`'s
    30 and collides with nothing in the driver compose — `orders_sdk`'s
    order-10 hook is manager-only.
  * Pure addition: no registration, guard, call site or UI surface was
    removed, and `app_type` has only a `driver` block, so customer builds
    composing `delivery_sdk` are untouched.

## 1.15.0

* Design strip section 49 — the driver's home screen, frames **49a**
  (on duty, nothing assigned), **49d** (off duty), **49e** (the 360
  fold) and **49m** (the wallet floor). All four are states of one
  composition, which is why they land together.
  * **What came out of `bottom_sheet_screen.dart`**: three hard-coded
    stock photographs on a 186.h horizontal `ListView`
    (deliveryhero.com, ctfassets.net and unsplash URLs baked into the
    source), the "Juvo benefit" promo tile, and a Balance tile reading a
    CACHED `LocalStorage.getUser()?.wallet?.price` whose tap handler had
    been commented out since it was written.
  * **931** — `DriverDayStrip`: earned / delivered / last fee, from
    `get_deliveryman_order_report` with today on both bounds. Driver home
    never called that endpoint; adopting it is a client change, not a new
    endpoint.
  * **932** — `CashOnHandCard`: the one number a driver could not see and
    most needs to. `settle_order` credits his fee AND debits his wallet
    by the gross cash he is carrying, so the old Balance tile was already
    net of money in his pocket with nothing explaining the gap. The
    wording is the wording frame 49d was REJECTED and redrawn for: "Cash
    on hand" / "docked from your wallet", never "Still to bank" /
    "deposit before your next shift" — no deposit doctype, due date or
    banking step exists anywhere in the fleet to back that claim.
  * **933/934** — `AvailableWorkQueue`: the offer queue, from
    `getAvailableOrders`, which was implemented and simply unconsumed by
    this screen. "first to claim" is a statement about the mechanism —
    `attach_order_to_me` succeeds only while `deliveryman` is empty, so
    two drivers tapping Claim is a race one of them loses, and the header
    says so before the tap. The card names a SUBURB and never a person,
    because `serialize_deliveryman_order` emits no user block at all.
  * **942** — the off-duty veil (`home_page.dart`): the map desaturated
    and dimmed and the zone outline drained to grey. Honest about what
    stopped — with `getOnline()` false the periodic `fetchBackground`
    task is cancelled and the 10-second routing poll never starts, so the
    map genuinely is no longer live.
  * **945/970** — `OffDutyRestCard` and `WalletPositionCard`: what
    replaces the carousel when he is not working, plus his wallet
    position stated as a SENTENCE rather than a signed number ("You owe
    R 1,240.00", not "−1,240"), naming the cause in his own terms and
    carrying the exit. It states no deadline, no deposit and no
    settlement obligation, because none exist.
  * **990/991** — `WorkPausedGate`: the screen half of the wallet floor
    shipped in zones#77. The guard already refuses work past the
    allowance but can only speak at accept time and, by design, its error
    carries no financial detail; the driver had no way to find out except
    by tapping Claim. The gate leads with the way out, states the
    operator's limit, and says that jobs already in hand are untouched —
    all true of the guard, which reads nothing on the collection path.
  * **49e, the fold** — a RE-LAYOUT, not a scale-down: at 360 the day
    strip becomes a headline figure with the two supporting numbers
    inline under a full-width rule, rather than three columns shrunk by
    `.w` until they collide. The cash card holds full weight; the number
    a driver is personally liable for does not get to be what degrades.
* **Backend, additive.** `get_deliveryman_order_report` gains
  `last_delivered_fee`, `cash_on_hand` and `cash_order_count`, all
  derived in the pass it already makes over rows it already reads;
  `_delivered_fields` asks for `cod_collected_amount` only on a site
  whose meta has it, so an unmigrated site reports zero rather than
  raising. New whitelisted `get_deliveryman_work_status` returns
  `{allowance, balance, owing, can_take_work}` through the SAME
  `resolve_deliveryman_wallet_allowance` and the SAME epsilon comparison
  the guard uses, so the gate on screen can never disagree with the guard
  that actually refuses the work. No policy is added anywhere.
* **Flagged, drawn on the frames, and deliberately NOT built** because
  nothing sources them: frame 49d's "SHIFT ENDED 17:04" (nothing records
  when duty was toggled — `setOnline` stores no timestamp), chip 934's
  customer name (no user block in the serializer) and chip 940's zone
  badge (needs the driver's live position plumbed into the sheet plus a
  point-in-polygon test). The day strip's `heading` parameter is where a
  real shift timestamp would land.

## 1.14.0

* Design strip section 49, frames **49b** and **49c** — the two driver
  surfaces that describe a job in progress. Both are draw-only: no
  endpoint, no notifier and no navigation changed in either.
  * **49b — the push offer, redrawn as a DECISION.**
    `push_order_screen.dart` was still the white upstream card
    (`AppStyle.white` at the panel, the ring collar and both avatar
    wells) — the last white surface on the driver's decision path, and
    the one screen he reads under time pressure. It now carries the
    fleet's dark tokens (`cardDark` / `cardDarkAlt` / `strokeDark`), the
    same set `CashCollectionSheet` adopted in 1.13.0, so the offer and
    the money step it leads to read as one app.
    * `PushOfferCountdown` — the ring, in a collar that is the sheet's
      own surface rather than a white disc floating over it, so the
      straddle reads. It owns NO clock: the page still computes the
      percent from the shipped `timerText` over
      `CourierHelpers.getAppDeliveryTime()` and hands it in. An
      out-of-range percent is clamped rather than thrown. Its track and
      progress arc move off a raw hex (`Color(0xFFF26110)`) and
      `shimmerBase` onto `AppStyle.primary` / `strokeDark`, so the ring
      re-brands with the composed app's palette like every other
      surface.
    * `PushOfferTimerNote` — the one honest line the frame asks for. The
      ring looks like a hold on the job. It is not: it is the OFFER
      expiring, and another driver can take the work while it counts.
      Nothing in the shipped screen said so.
    * `PushOfferLegs` — the two legs NAMED. The shipped layout already
      drew shop, two dots, then customer, and never said which end was
      which; PICKUP and DROP-OFF are the two things being decided
      about. Same fields, same payload, nothing added or dropped.
    * Untouched on purpose: the timer maths, the `ref.listen`-on-
      `isTimeOut` pop, `goMarket`, `getRoutingAll`, both buttons and the
      COD line.
  * **49c — the job rail.** `delivery_bottom_sheet.dart` told the driver
    where he was in the job with exactly one thing: the caption on the
    primary button. `DeliveryStatusRail` draws the arc instead —
    Accepted, At shop, On a Way, Delivered.
    * The rail is DERIVED and invents nothing. The Order doctype carries
      no "at shop" status and this does not pretend it does: the second
      node is earned at the `completeCheckout` confirmation, which is
      the same local transition that already swaps the button's
      caption. `DeliveryStatusRail.stageFor` is the whole derivation and
      it is pure, so the reading is under test without a notifier.
    * No new state, no new call: the server `status` already on the
      sheet plus the two live flags `HomeState` already keeps.
  * Six new driver `tr_keys`: accepted, atShop, onAWay, delivered,
    dropOff, offerCountdownNotAHold. `TrKeys.pickup` is base's own.
  * `cached_network_image` is now a declared dependency (49b's leg strip
    draws the shop and recipient avatars from `lib/`; it was previously
    reached transitively through base_sdk) — same reason `auto_route`
    was declared in 1.13.0.
  * Both widgets live in `lib/` rather than in the installed template,
    which puts them under CI: `templates/**` is excluded from analysis
    fleet-wide.
  * FOLLOW-UP, deliberately out of scope and unchanged by this release:
    this package has no `tool/inject_tr_keys.dart`, so a STANDALONE
    `flutter test` run fails to load every suite that touches a
    manifest-declared key until the resolved `base_sdk` checkout has
    the manifest's `tr_keys` injected by hand. merchants_sdk ships that
    harness tool; delivery_sdk does not.

## 1.13.0

* Gate 3 of design strip section 45 — the deliveryman's cash step
  (frame 45d, chips 844/845/846, canonical 390). The cash-collection
  dialog was a WHITE alert dialog driving the OS keyboard
  (`AppStyle.white`, `AppStyle.black` buttons, an
  `UnderlinedBorderTextField` on `numberWithOptions(decimal: true)`) —
  the last money-entry surface in the fleet not on chip 390, on the one
  screen where a driver is one-handed in the sun.
  * **844** — `CashCollectionSheet` (`lib/src/driver/presentation/
    widgets/cash_collection_sheet.dart`): a dark bottom sheet in the
    fleet language — drag handle, order header, the shipped
    Cash-to-collect card, the amount question (the same
    `TrKeys.howMuchCashReceived` string), a NON-FOCUSABLE amount
    read-out, base_sdk's `MoneyKeypad` in place of the text field, then
    Confirm / Record as credit. Living in `lib/` rather than in the
    installed template puts the whole surface under CI, which excludes
    `templates/**` fleet-wide.
  * **845** — the "Count it" step: a small primary-tinted chip beside
    the read-out that opens `/calc?pick=true` and drops the
    calculator's total into the entry. Navigation is BY ROUTE PATH, so
    delivery_sdk still never imports calc_sdk (ADR-005), and a
    composition on a calc_sdk older than 1.1.0 simply gets null back
    and the driver keeps typing.
  * **846** — the delta line: red-washed while the count is short,
    green once it is exact or over. DERIVED in the widget from the
    `order.totalPrice` already on the sheet minus what is typed — the
    server stays the authority on the expected amount.
  * Behaviour around it is untouched: the same
    `confirmCodCollection` -> `confirm_cod_collection {order_id,
    amount_received}` and, gated on `can_convert_cod_to_credit`, the
    same `convertCodToCredit` -> `convert_cod_to_credit`, with the same
    success paths into `_finishDelivery`.
  * `auto_route` is now a declared dependency (route-path navigation
    from `lib/`; it was previously reached transitively through
    base_sdk). Four new driver `tr_keys`: countIt, shortOf,
    overExpected, amountMatchesExpected.
  * FOLLOW-UP, deliberately out of scope: the `RateCustomer` sheet that
    follows this one is still `isDarkMode: false`, and the cancel
    dialog is still a white alert — the same light-surface debt,
    flagged on frame 45d and left alone here.

## 1.12.0

* Floating-nav back conversion (approved design strip section 12, "no
  double back buttons" — base_sdk 1.39.0 / core#125): the six driver
  template pages (orders, parcels, order_history, parcel_history, route,
  profile) plus the common DeliveryPage and BecomeDriverPage replace
  their standalone `PopButton` with the shared `FloatingBottomNav`
  carrying only the leading back segment — one back per screen.
  Back-only (empty tab list): the driver app composes no root tab set,
  and the customer-app pushed routes cannot reach the host's root tabs
  from this SDK. Surviving bottom actions (the history pages' filter
  button, the driver profile's online-helper button) keep their spot —
  the filter stays right-edge, the helper rides in the same bottom
  overlay above the pill.

## 1.11.0

* Driver repoint wave (client side of zones#68 / Users#64): the last dead
  Laravel `/api/v1/dashboard/*` calls in the driver repositories now go
  through the universal platform gateway to whitelisted Frappe defs.
  * `orders_repository`: getAvailableOrders ->
    `api.delivery_man.get_available_orders`; showOrders ->
    `api.delivery_man.get_deliveryman_order_details`; addReview ->
    `api.delivery_man.add_deliveryman_order_review`; getHistoryOrders /
    fetchCurrentOrder -> `api.driver_order.get_driver_orders_paginate`
    (statuses + the new date_from/date_to bounds).
  * `courier_repository`: getDriverDetails ->
    `api.delivery_man.get_deliveryman_settings` with a client-side fold
    of the Deliveryman Profile map into the legacy `DeliveryResponse`
    (car_model/car_number/vehicle_image -> model/number/galleries[0]);
    editCarInfo -> `api.delivery_man.update_deliveryman_settings`;
    getDeliveryZone -> `api.delivery_man.get_deliveryman_zone_polygon`;
    updateGeneralInfo -> Users' `api.user.update_profile` (+ a separate
    `api.user.update_password` call when a password change rides along);
    createCarInfo -> `api.user.create_request_model`; getRequestModel ->
    `api.user.get_user_request_models` with never-throw row
    normalization (JSON-string `data` decoded, hash-string ids dropped
    from the legacy int fields).
  * getDeliveryVehicleTypes still speaks its legacy path (server-side
    whitelist pending; tracked as a follow-up).

## 1.10.1

* FIXED Windows driver build dying before its first frame: the
  `delivery-driver-courier-location-workmanager` boot hook ran an
  unguarded `await Workmanager().initialize(callbackDispatcher);` in the
  composed `main()` before `runApp`. workmanager only ships Android/iOS
  implementations, so on a composed Windows exe the call threw
  "No implementation found for workmanager on this platform" and the app
  exited with no window (taskbar icon flash only). The hook body is now
  wrapped in the fleet boot-hook guard idiom (Android/iOS platform
  allowlist + fail-open try/catch with a debugPrint, same shape as
  comms' firebase-fcm boot hook) - desktop and web skip the courier
  background tracker, which they never supported anyway. No behavior
  change on Android/iOS.

## 1.10.0

* Driver order ids migrated int -> String (the fleet-wide docname
  migration's last straggler; the customer path was already done).
  Order docnames are Frappe default hash strings (the commerce Order
  doctype has no autoname), so the driver flavor's `int? orderId`
  surface could only ever address numerically-named orders:
  * `OrderDetailData.id`, `Details.orderId` and `PushModel.orderId` are
    now `String?`; `fromJson` prefers the always-present `name` key and
    falls back to the legacy numeric `id` for older payloads.
  * `CourierOrdersRepositoryFacade` / `CourierParcelRepositoryFacade`
    and their HTTP + demo implementations now take String order/parcel
    ids throughout (base_sdk's `ParcelOrder.id` was already a String —
    the parcel templates were round-tripping it through `int.tryParse`,
    which nulled out every hash docname).
  * FIXED silent delivered no-op: `deliveredFinish` (and the parcel
    twin) used to send `orderId ?? 0` — on a hash docname the serializer
    emits `id: null`, so the driver marked the order delivered while the
    backend updated nothing. A null id now aborts with a logged error
    instead of sending 0, and the delivered status update's result is
    checked, surfacing backend failures to the courier.
  * Wire-compatible: the backend endpoints are untyped and
    `serialize_deliveryman_order` already always emits `name` (its
    numeric-only legacy `id` emission is kept for old builds) — no
    frappe changes.
  * Demo seed order ids became strings ("900001"), matching real
    docnames end-to-end in demo mode.

## 1.9.2

* Driver ID verification for 18+ orders (`contains_adult_items`, the
  additive flag the commerce module stamps on orders with adult
  products):
  * `OrderDetailData` gains `containsAdultItems` (backend key
    `contains_adult_items`, absent-when-false, defaults to false), so
    old payloads keep parsing unchanged.
  * Upfront notice: the driver `OrderItem` component - rendered on the
    order card and in the delivery bottom sheet - shows an
    "ID required, recipient must be 18+" banner on flagged orders, so
    the courier knows BEFORE arriving at the customer.
  * Completion gate: every delivered path (plain, cash collection,
    record-as-credit) now funnels through a required
    "Check recipient's ID: 18 or older?" confirm dialog on flagged
    orders (cash-collection dialog precedent); only on confirm does
    `deliveredFinish` run, threading `recipient_age_verified: true`
    through `updateOrder` into the gateway payload. Only the yes/no
    confirmation travels - no ID image or document data is ever
    captured or stored.
  * Backend counterpart: map's `update_driver_order_status` accepts the
    OPTIONAL `recipient_age_verified` param and refuses to complete a
    flagged order without it (`AGE_VERIFICATION_REQUIRED`); delivery's
    `serialize_deliveryman_order` emits the additive
    `contains_adult_items` key (weather_notice absent-when-false
    precedent). Old driver builds keep working for all non-adult orders;
    flagged orders require a recomposed app - intended enforcement.
  * New driver tr_keys: `idRequired18Plus`, `checkRecipientId18Plus`.

## 1.8.0

* Courier home: severe-weather heads-up banner. The home bottom sheet
  (`templates/pages/driver/home/bottom_sheet_screen.dart`) now renders
  weather_sdk's `weatherWarningsBanner` through base_sdk's
  `EmbeddedWidgets.I` seam (ADR-005 - no weather_sdk import), docked just
  above the fixed-height sheet card so a variable-height notice can never
  overflow it.
  * Fail-closed by construction: the seam call is dispatched dynamically
    inside a try/catch because weather_sdk is optional in courier
    compositions - without it the host's `EmbeddedWidgets` has no
    `weatherWarningsBanner` implementation (base_sdk's interface does not
    declare the method either, so a static call would not even compile)
    and `noSuchMethod` throws; the guard turns that into
    `SizedBox.shrink()`, so the courier home renders nothing extra and
    never crashes. When weather_sdk IS composed, the banner itself renders
    nothing unless there is an active notice.
  * The banner resolves the courier's own position via the
    `WeatherSdkConfig.locationResolver` wired by weather_sdk 1.4.0's new
    driver-flavor template (base_sdk's selected-address slot, which
    `CourierStorage.saveSelectedLocation` keeps at the courier's live map
    position).

## 1.7.2

* Repointed the driver repositories' remaining legacy
  `/api/v1/dashboard/*` call sites that have a real Frappe equivalent to
  the versioned method surface:
  * orders repository: `setCurrentOrder`, `uploadImage` and `setOrder`
    (attach) now go through the universal platform gateway to the map
    module's whitelisted driver_order defs
    (`api.driver_order.set_current_order` / `.upload_order_image` /
    `.attach_order_to_me` — the map manifest registers those alias keys
    in this wave); `cancelOrder` goes through the gateway to the
    registered `api.driver_order.update_driver_order_status` (the alias
    1.7.1 added), same as its sibling `updateOrder`.
    `setOrder` answers an empty `OrderDetailModel` on success (the def's
    raw doc dict is not OrderDetailData-shaped and the only caller
    ignores it); `cancelOrder`'s legacy `note` is not persisted (the def
    takes no note kwarg — known gap).
  * parcel repository: `setCurrentOrder`, `addReviewParcel` and
    `setParcel` (attach) now go through the universal platform gateway
    to the delivery module's whitelisted driver_parcel defs
    (`api.driver_parcel.set_current_parcel_order` /
    `.add_parcel_order_review` / `.attach_parcel_order_to_me` — alias
    keys the delivery manifest registers in this wave).
  * courier repository: `setOnline` goes through the universal platform
    gateway to the registered `api.delivery_man.
    update_deliveryman_settings` method, expressing the legacy
    server-side toggle as the explicit desired value from the same
    `CourierStorage` cache its caller flips on success.
* Sites with NO registered Frappe equivalent or a genuine payload/shape
  mismatch were deliberately left on their (dead) legacy paths and are
  listed as decision items in zones PR #30: available/history/current
  order+parcel lists, single order/parcel show, order review,
  deliveryman settings (get + vehicle update), profile update,
  request-models (get + create) and the courier delivery-zone polygon
  read/write.

## 1.7.1

* Routed every driver call site added in the 1.6.0 (COD) and 1.7.0
  (routing) waves through base_sdk's universal platform gateway
  (`PlatformGateway`, per the 2026-08-15 fleet rule): the old direct
  `/api/method/paas.api.*` dotted paths become prefix-free gateway cmds
  (`api.driver_order.*`, `api.driver_parcel.*`, `api.dispatch_route.*`,
  `api.delivery_man.get_deliveryman_settings`, `api.driver.update_location`)
  mirroring the owning modules' `manifest.json` whitelisted-method keys.
  GET-style reads (`get_driver_orders_paginate`, `get_driver_route`,
  `get_my_dispatch_route`, `get_deliveryman_settings`) become gateway
  POSTs. The Workmanager background-isolate location report builds the
  same gateway request by hand (no DI in that isolate) against
  `kPlatformGatewayPath`. Registered the two whitelisted-method manifest
  keys the gateway needs to dispatch the status updates
  (`api.driver_order.update_driver_order_status` in map,
  `api.driver_parcel.update_driver_parcel_order_status` in delivery) —
  they were only reachable by their direct composed dotted paths before.
  Pre-existing legacy `/api/v1/*` calls are untouched.

## 1.7.0

* Driver route optimization wave:
  * New "My Route" page (`/driver-route`, launched from a route button on
    the courier home map): numbered, server-ordered stop cards — label,
    stop type, leg distance, per-stop quantity+unit, "Cash to collect"
    chip — with the next pending stop highlighted; tapping a stop hands
    off to `map_launcher` (existing MapsList sheet). The backend
    (`get_driver_route`) is authoritative for ordering: greedy
    nearest-next from the driver's position, pickups before their own
    drop-offs, coordinate-less stops flagged at the tail.
  * Admin-composed Dispatch Routes (Pickup or Delivery mode, per-stop
    quantities — the water-run case) surface on the same page via
    `get_my_dispatch_route`; dispatch stops carry Done / Skip actions
    (`complete_dispatch_stop`) and the list re-fetches (and re-orders)
    after every completion.
  * Rewired `getActiveOrders` from the dead legacy
    `/api/v1/dashboard/deliveryman/orders/paginate` path to the working
    `get_driver_orders_paginate` Frappe endpoint (now returning
    data+meta with parsed coordinates, nested shop and payment tag);
    `OrderDetailData.id` parses tolerantly since Frappe names are
    strings.
  * Rewired courier location reporting (10-minute Workmanager background
    task + foreground `setCurrentLocation`) from the dead legacy
    `/api/v1/dashboard/deliveryman/settings/location` path to
    `paas.api.driver.driver.update_location` with
    `{latitude, longitude}` — this position seeds the route optimizer.
  * New driver tr_keys: `myRoute`, `pickupRoute`, `deliveryRoute`,
    `noRouteStops`, `noLocationForStop`, `quantity`.

## 1.6.0

* Driver COD (cash-on-delivery) wave:
  * Prominent "Cash to collect" line on cash orders in the courier order
    card, the push-order sheet and the delivery bottom sheet (tag ==
    'cash' via `order.transaction?.paymentSystem?.tag`).
  * Delivered flow on cash orders now confirms the amount actually
    received (prefilled with the order total, editable) after the
    proof-of-delivery photo and BEFORE `deliveredFinish`; a failed
    backend confirm keeps the dialog open so the order is never
    delivered-but-unrecorded. Drivers whose `can_convert_cod_to_credit`
    capability is enabled get a secondary "Record as credit" action.
  * Parcel delivered flow: parcels with a sender-declared
    `codAmount` (base_sdk ParcelOrder) show "Collect from recipient" and
    confirm the collected cash (backend settles deliveryman wallet ->
    sender wallet) before `deliveredFinishParcel`.
  * Rewired `updateOrder` / `updateParcel` status posts and the new COD
    endpoints from the dead legacy `/api/v1/dashboard/deliveryman/*`
    surface to the Frappe `/api/method/paas.api.*` convention; new
    `getDeliverymanSettingsRaw()` reads the per-driver capability flag
    without touching the legacy `DeliveryResponse` model.
  * New driver tr_keys: `cashToCollect`, `codConfirmed`,
    `collectFromRecipient`, `howMuchCashReceived`, `recordAsCredit`.

## 1.5.0

* Post-compose APK fix round for paas_driver (Build (Smart) run 31635788470,
  87 Dart compile errors), courier vertical aligned with the shared kernel:
  * `ImageCropperMarker` -> base_sdk's `ImageCropperForMarker` (same class,
    base's name; the courier pages already imported base's
    `marker_image_cropper.dart`, only the identifier was stale).
  * Selected-location storage: the legacy host stored a bare `LatLng` under
    `keyAddressSelected`; base's `LocalStorage.setAddressSelected` takes an
    `AddressData`. New `CourierStorage.saveSelectedLocation(LatLng)` wraps
    the coordinates in `AddressData.location`, and reads go through the new
    `AddressData.latitude`/`longitude` getters (base_sdk 1.9.0).
  * Language flow: `LanguageScreen(afterUpdate:)` (host-era widget, never
    composed) -> `EmbeddedWidgets.I.languageScreen(onSave:)` (comms_sdk's
    embedded widget, manager precedent) +
    `AppNotifier.changeLocale` instead of the host's `changeLanguage`.
  * `Delayed` import (base_sdk `tpying_delay.dart`) in the home page.
  * Dropped the host-era no-op args base's helpers never had:
    `AppHelpers.numberFormat(maxLength:)` (self-assigned, dead in the old
    host too) and `showCustomModalBottomSheet(isExpanded:)` (accepted but
    unused in the old host).
  * `ParcelOrder.id` is `String?` in base (commerce/orders consumes it as
    String); the courier notifier's `int?` params now get `int.tryParse` at
    the four call sites.
  * De-consted widgets using brand-mutable `AppStyle.primary`/`shimmerBase`
    (order_history, parcel_history, bottom_sheet_screen, orders_item,
    rate_customer, underline_bordered_text_field, edit_car — commerce#18
    story_page precedent) and const-qualified shop_avarat's default
    `Color` value.
  * Manifest: `confirmPasswordDoesntMatchWithNewPassword` tr_key (used by
    edit_profile_modal, absent from base).

## 1.4.0

* (retro note; shipped without a CHANGELOG entry) `app_routes`
  replaceMainRoute -> /home for driver composes; courier location boot
  hooks (zones PR #14).

## 1.3.0

* Courier vertical build-out (S-D3 of the paas_driver lib-regenerable plan):
  `lib/src/driver/` role slice ported from paas_driver main — application
  slices (home map, orders, parcels, push-order, driver, vehicles, profile),
  the Laravel deliveryman repositories moved AS-IS (decision D2:
  `CourierOrdersRepository`, `CourierParcelRepository`, `CourierRepository`
  over `/api/v1/dashboard/deliveryman/*`), courier-only models, and
  `DriverDeliveryDependencies` (di hook, revenue_sdk precedent).
* Driver templates installed to the exact host paths paas_driver's tracked
  router/pages import today: pages (home ×10, orders, order history, parcels
  ×3, parcel history, push order, profile ×7 incl. the new
  `courier_statistics_provider.dart` revenue seam, become-driver shell),
  components ×14 (incl. restaurant_item / product_item / maps_list per
  decision D3 and seven custodianship copies of driver-only widgets), and
  `delivery_adapters.dart` (vehicle-capture adapter).
* Manifest: real `home_page` template (the key existed since 1.2.0 without
  the file), `home_sdk` flag, `app_type.driver` routes for
  /home /orders /order-history /parcels /parcel-history /profile
  /become-driver, `session_policy` (deliveryman → /home, `*` fallback →
  /become-driver pending decision D1 / auth_sdk S-D4), the
  `delivery.vehicle_details` registration step (`VehicleDetailsSlide`,
  decision D5 scope: the legacy become-driver form's fields only),
  `app_routes` (replaceLoginRoute), 31 courier `tr_keys`, `asset_keys`
  (pngMyLocation, svgBalance) + custodianship asset copies.

## 1.2.0

* (pre-existing) delivery points repository, delivery/become-driver common
  pages, splash/marker custodianship assets.
