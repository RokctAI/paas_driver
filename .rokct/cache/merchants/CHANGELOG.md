## 1.20.0

* DELIVERY COLLECTED IN PERSON — the server half (approved design strip
  section 43). ONE new atomic seller endpoint,
  `convert_delivery_to_collected(order_id)`, whose whole point is that it
  is one call: a client-orchestrated sequence that fails half way leaves
  an order that is half converted — a Pickup order still carrying a
  driver, or a driver stood down on an order that never converted. Any
  throw rolls the whole request back.
  * Ray's policy rendered literally. **No driver had been dispatched** →
    the delivery fee goes back to the customer's wallet (`deposit_to_wallet`,
    which writes the Transaction audit row) and `delivery_fee` is zeroed,
    so `calculate_totals` drops the order's total by it. **A driver HAD
    been dispatched** → he still drove for it, so the fee is kept and paid
    to HIM as a callout (a new `settle_delivery_callout` in orders'
    settlement module, gross fee credited and delivery commission billed
    back exactly as an ordinary settlement would), the total is unchanged,
    and his task disappears from the driver app the moment `deliveryman`
    is cleared. Either way the goods go over the counter.
  * **THE ORDER OF THE WRITES IS THE POINT.** The Order controller settles
    on every save once the order is Delivered + Paid, and `settle_order`
    credits the deliveryman the FULL `delivery_fee` while he is still
    assigned. So the callout is paid and the assignment cleared in the
    FIRST save, with the order still short of Delivered; only the second
    save moves it to Delivered, by which time it carries no driver and the
    settlement pays him nothing. Reverse the two and he is paid twice.
    `merchants/frappe/tests/test_collect_in_person.py` pins that on his
    wallet balance — 35.00 in the right order, 70.00 in the wrong one.
  * Idempotent (`already_converted`), which is what makes the till's
    offline path safe: the hand-over happens immediately and the
    conversion is replayed on reconnect without moving money twice.
  * `get_seller_order_details` additively serves `deliveryman_name`, so
    the detail can SAY who is on the order rather than showing a user id;
    `get_seller_orders` additively serves `delivery_type`, `delivery_fee`
    and the two new conversion fields the board card needs.
  * Four new read-only Order fields carry it: `collected_in_person`,
    `collect_fee_refunded`, and `callout_settled` / `callout_settled_at`
    (the callout's own once-only flag). `deposit_to_wallet` gained an
    additive `commit` flag so a credit that is part of a larger
    all-or-nothing write is not committed out from under a later failure;
    every existing caller keeps the old behaviour.

## 1.19.0

* QUICK FLOW (approved design strip section 42, frames 42a tablet / 42b
  phone / 42c the till inset): a new merchant settings surface — one
  place where a shop tells the till to run itself between customers —
  reached from a new **Quick flow** row inserted SECOND into the
  restaurant tab's Sections list (chip 795; the other five rows are
  untouched). Three switches, and the surface never pretends they are
  peers:
  * **Auto-accept incoming orders** (797) is `Shop.auto_approve_orders`,
    a field that ALREADY EXISTED and was already honoured by
    `create_order` — the row exposes that exact field and NOTHING
    server-side changed for it, which is what the `LIVE · SERVER` badge
    means. The gate line under it (798, a wide read — dropped on the
    phone) is the doctype's own description: the platform's *Auto Approve
    All Orders* has to be on too, or nothing moves.
  * **Auto-complete at Ready** (799) is NEW on both sides: a new
    `Shop.auto_complete_at_ready` field and a new Order-controller rule
    (commerce/orders, `complete_at_ready_if_due`). Drawn and defaulted
    OFF, carrying the hand-over warning (800) in as many words —
    orders complete with nobody confirming the customer took them.
    PICKUP ONLY, and never on insert: a travelling order is never
    completed by it (settlement pays the deliveryman the full fee on
    Delivered), and a packed send-for-delivery POS sale is created
    holding Ready and must stay there.
  * **Keypad autodial** (802) with the DIGIT PRESETS grid (803/804/805,
    3-up at plane width and 1-up on the phone — the column count is the
    only thing that changes) is a NEW per-shop digit→product map. Slots
    are filled through the till's own catalog seam
    (`PosCatalogRepositoryFacade`), so this SDK still never imports
    products_sdk (ADR-005).
  Planes: a `PlaneHost` whose root is the merchant Sections rail (795,
  Quick flow lit) and whose active step claims TWO planes — more space
  buys more detail, not zoom — folding to one plane on the phone with
  the wide-read extras dropped (42b). The corner back pill at the
  bottom-END (canonical 347) is `PlaneHost`'s own; this is a pushed
  surface, so it is the only nav affordance on screen. Every switch
  writes THROUGH to the shop and REVERTS if the server refuses: no local
  draft and no Save button, because two of the three change what the
  till does the moment they move.
* KEYPAD AUTODIAL on the till (42c): while there is NOTHING on the
  ticket, a digit key is not money — it is the item the shop mapped to
  that key, dropped straight on the ticket; once an item is on, the keys
  are money again. The hint strip (807) is present only while the ticket
  is empty (it is the visible form of the arming rule), each armed key
  prints its preset's name UNDER THE NUMERAL (806), and the strip along
  the bottom says what landed (808). An unset digit is INERT, not an
  error (805). **base_sdk's `MoneyKeypad` (chip 390) is NOT modified** —
  it emits the same key events it always did and the till decides what a
  press MEANS; the captions are a caller-side overlay on the pad's own
  published geometry under an `IgnorePointer`. Chip 390's
  pure-input-surface contract stays intact fleet-wide. The till's
  Continue stays live on an empty ticket ONLY while autodial is armed,
  because the pad lives on the payment surface and is how the ticket
  gets built; unarmed shops see exactly the gate they always saw, and
  while the pad is armed the "Amount paying now" card yields so there is
  never a second keypad on the page.
* Backend (commerce/merchants + commerce/orders): `Shop` gains
  `auto_complete_at_ready`, `keypad_autodial` and the `digit_presets`
  child table (new `Shop Digit Preset` doctype, digit 1-9 → Product);
  `seller_shop.get_quick_flow_settings` / `update_quick_flow_settings`
  read and write the surface as one unit (the writer OWNS the whole 1-9
  map and refuses a bad digit, a digit mapped twice, a missing product
  or another shop's product), serving each preset's product already in
  the client's `ProductData` shape so a digit press never waits on the
  network.
* Tests: `quick_flow_settings_test.dart` (the model's reads and the
  notifier's write-through-and-revert), `quick_flow_page_test.dart` (the
  three switches and what each says about itself, the preset grid and
  its counter, and the fold), `pos_checkout_autodial_test.dart` (the
  arming rule driven through the REAL shared keypad, asserting on the
  cart). Server-side: `test_auto_complete_at_ready.py` (every guard the
  new rule refuses on, bench-free) and `test_seller_quick_flow.py` (the
  two endpoints under composer substitution).

## 1.18.0

* SYNC ISSUES adopts the standard list language (approved design strip
  frame 38c, Ray 2026-08-30 12:23Z: "33 list language = STANDARD for all
  lists ... the box tabs are IN"). The park-and-surface screen is the
  only manager list whose cards carry ACTIONS, which is why the frame
  puts it at the two-plane fold: if the treatment holds here it holds
  anywhere.
  * New `src/manager/presentation/sync_issues/sync_issue_boxes.dart`:
    `SyncIssueBox` — the record's box as a filter (chip 710, the other
    genuinely new affordance Ray ruled IN): All / Shop / Product / Order,
    colour-coded per the 33a set (Shop = base blue, Product = rate
    yellow with dark pill text, Order = primary), each filtering and
    counting its own box. A record from a box with no tab of its own
    still shows under All, so nothing can vanish from the list.
  * New `src/manager/presentation/sync_issues/sync_issue_card.dart`:
    `SyncIssueCard` — the shipped card in the 33 dress (chip 708): box
    glyph + label in the box's own colour, the record summary, the
    server's rejection message in red, and the shipped action pair
    Try again / Discard (chip 709). Plus the needs-attention header hint
    (chip 711).
  * The installed `sync_issues_page.dart` is rebuilt on those pieces plus
    base_sdk's list language: header count pill "N parked" (700), the box
    tabs, cards in plane-aligned columns, the corner back pill (347), and
    the shipped empty state kept. The list declares TWO planes and fills
    the fold exactly. Discard still goes behind the shipped are-you-sure
    dialog; Try again still requeues the parked push.
  * Requires base_sdk >= 1.46.0 (the list language).
  * Test: `sync_issues_list_language_test.dart` — the tab set matching
    `SyncIssuesService.boxes`, per-tab filtering and counts, the untabbed
    box still reachable under All, the 33a colours, and the card's label
    / summary / rejection message / action pair.
## 1.17.0

* The user-card edit pencil returns (chip 109, approved frame 4d
  2026-08-30): `registerMerchantProfileSections()` now wires
  `ProfileSectionRegistry.I.onEditProfile` (next to the `onLogout ??=`
  block, `??=` so a host that already owns the affordance keeps its
  wiring), so base_sdk's GenericProfilePage renders its gated pencil on
  the manager's unified identity card again — the manager app regains an
  edit-OWN-details path, the gap Ray reported after the chip-243
  shop-pencil move (PR #80; the user card had shipped pencil-less since
  the profile-host adoption in PR #75). The pencil opens base_sdk's
  shared edit sheet (base_sdk 1.45.0 — the shipped customer
  `EditProfileScreen`, promoted; email, firstname | surname, phone,
  birth date, gender, avatar photo-pencil, Save) as the standard drag
  bottom sheet in the current theme mode. Save was already plumbed end
  to end (base_sdk `editProfileProvider` -> the self-scoped
  `update_user_profile` endpoint) — NO backend change, and the SHOP
  pencil (chip 243) on the shop info row is untouched.
* Test: `profile_edit_pencil_gate_test.dart` — the host's user-card
  pencil stays hidden while `onEditProfile` is unset and renders (and
  fires) once it is wired, with the shared base_sdk sheet resolvable
  from this SDK's dependency graph.

## 1.16.0

* THE KEY PAD at checkout (design chip 390 — approved frame 11u, tablet
  2026-08-29 15:41Z, and frame 11y, phone 2026-08-30): the
  "Amount paying now" typed `TextField` (`posPaidNowField`) is replaced
  by base_sdk's shared `MoneyKeypad` (base_sdk 1.44.0 — Ray's standing
  direction: the keypad is the standard money-entry surface fleet-wide,
  so delivery/wallet/calc adopt the same component later). The amount
  display (chip 336) is now a plain read-out that CANNOT focus — the OS
  keyboard never appears (the 11y ruling); digits, the `00` money key,
  ⌫ and the `.` | OK confirm row do the editing, with calculator-entry
  freshness (the prefilled total is REPLACED by the first keypress; the
  Full / all-on-credit quick chips and OK re-arm it) and OK normalizing
  to the clamped two-decimal amount the sale takes. At plane widths the
  keys grow to the card's full width (11u's two-plane spread); on phone
  it is the 11y one-plane fold. Everything else is unchanged: prefill,
  change/credit remainder math, quick chips, customer attach, Cash | QR,
  delivery state and the dual finish buttons.
* Key feedback (the paas_pos tender-pad recipe, carried by base_sdk
  `KeySound` behind its persisted default-ON gate): every keypress plays
  tap.wav + a light haptic; refused finishes (delivery without customer/
  address, a failed print, a failed submit) and a rejected 6-digit code
  play the wrong.wav error buzz.
* Tests: `pos_checkout_keypad_test.dart` (the 11y no-OS-keyboard gate,
  keypad editing end to end into the submitted draft, quick-chip
  freshness); the credit-split test now drives the keypad instead of
  typing.

## 1.15.0

* Backend: `get_seller_profit_report` — the one endpoint behind the
  approved revenue/statistics dashboard (design section 36, Ray's
  2026-08-29 14:51Z profitability requirement, approved 2026-08-30
  10:38Z). Shop-scoped (`_get_seller_shop`, the kitchen `cook.py`
  pattern) profitability aggregates over Order / Order Item: profit per
  line `(price − cost_price) × quantity` strictly from the `cost_price`
  snapshot frozen at sale (order.py's create path), lines with
  `cost_price <= 0` into the UNKNOWN bucket (excluded from profit and
  from the margin denominator — never counted as free/100% margin, the
  approved cost-0 ruling), `margin_pct` over COSTED revenue only.
  Returns `totals` / `unknown_bucket` / `series` (per-day, per-hour when
  `from_date == to_date`) / `products` (with the current Price/Cost for
  the 35a strip and `cost_missing`) / `status_counts` (split-bar wire
  vocabulary; `Ready` counts under `cooking`, `Paid`/`Failed` stay out
  of the bar). Whitelisted as `api.seller_report.get_seller_profit_report`
  so revenue_sdk's existing `api.seller_report` `_cmd` path reaches it.
  `get_order_report` / `get_order_report_paginate` are untouched — the
  payout strip and today count still read `get_order_report`, and
  previous-period deltas come from the client re-calling the new
  endpoint for the shifted window. Bench-independent contract tests
  cover the bucket math, hourly series, product ordering and shop
  scoping (`tests/test_seller_report_contract.py`).

## 1.14.2

* Restaurant tab (the manager profile hub): the approved PRODUCTIVITY
  gate (frame 7e, chip 391 — Ray 2026-08-29 15:06Z "we can expose it.
  that will be productivity gate", approved 15:41Z). A new
  `merchants.productivity` section (order 125) gives productivity_sdk's
  composed-but-orphaned `/tasks` page its one entry point: a PRODUCTIVITY
  group title plus the Tasks row, routed like every other hub row via the
  host's generated `TasksRoute`. Order 125 closes plane 1 under the
  restaurant content at two-plane widths while wallet/sections/footer
  keep plane 2, exactly the approved 7d distribution. `SectionsItem`
  gained an optional `subtitle` glance line (grey, under the title);
  demo composes seed the approved "3 open · 1 due today" glance — live
  counts wait for the `/tasks` screen's own design pass (coverage-map
  group M), since merchants_sdk cannot read productivity task data
  (ADR-005). New manager tr_keys: `productivity`, `tasks`. Manager
  composes pair with productivity_sdk (the manager composer list already
  carries it); the `/tasks` screen itself is unchanged — this is gate
  exposure only.

## 1.14.1

* Manager home shell: the create FAB no longer rides the foods tab (index
  3) — the approved product-management workspace (products_sdk 1.6.0,
  frames 35a/35c, Ray 2026-08-29 15:41Z) carries its own "+ New product"
  header action with the same inner-tab create dispatch, and the approved
  floating-nav language has no FAB. The orders tab (1) keeps its create
  button in both nav shapes (bottom pill and tablet-mode rail). Composes
  that include merchants_sdk's manager block pair with products_sdk >=
  1.6.0.

## 1.14.0

* Manager home shell mounts the KITCHEN tab (the approved manager Kitchen
  screen, kitchen_sdk 1.3.0, frames 34a–34d — Ray 2026-08-29 13:06Z /
  13:53Z): `main_page.dart` imports the kitchen_sdk-installed
  `pages/kitchen/kitchen_page.dart` at index 2, between the order queue
  (1) and foods (now 3); the restaurant/shop-profile tab moved to 4. Both
  nav shapes (bottom pill and the tablet-mode rail) gained the bowl-icon
  Kitchen destination; the create FAB rule follows foods to index 3 (the
  kitchen creates nothing). Composes that include merchants_sdk's manager
  block now REQUIRE kitchen_sdk >= 1.3.0 alongside it (the manager
  composer list already carries kitchen_sdk), exactly as the shell
  already requires orders_sdk's and products_sdk's page installs.

## 1.13.1

* `mobile_scanner` aligned with hardware_sdk: `^5.1.0` -> `^6.0.4`
  (resolves 6.0.11). The 1.13.0 POS till pinned the 5.x line while
  hardware_sdk pins `^6.0.4`; the two caret ranges have an empty
  intersection, so any composer (paas_manager) depending on both SDKs
  failed version solving. No till code changes: the Dart API surface the
  BillingPage template uses (`MobileScannerController(detectionSpeed:)`,
  `start`/`stop`/`dispose`/`toggleTorch`, `MobileScanner(controller:,
  onDetect:)`, `BarcodeCapture.barcodes.first.rawValue`) is unchanged in
  6.x — 6.0.0's breaking changes are platform-level (iOS 15.5 minimum,
  MLKit 7, Xcode 15.3). Scanner pause/resume, barcode -> addByBarcode
  forwarding, and the debugConnectivityOverride seams are byte-identical.

## 1.13.0

* POS till ships per Ray's approvals (2026-08-28, strip 11a–11i:
  "approved: 11i, 11c-h" + 11a/11b with the icon dedup):
  * BillingPage deltas (11a/11b): the Scan lane (chip 276) moved INTO
    the viewfinder stage (273), centered, in chip 227's settings-row
    idiom — leading scan glyph + semi label + trailing chevron on a
    light card (Ray's icon dedup: the stand-in's ghost scan watermark is
    removed, the lane keeps its glyph); Add Items keeps the lane row and
    its sheet follows new frame 11j (chips 316-321: the 171-pattern bare
    title row + the section-12 back-only floating pill dismissing the
    sheet); the
    summary (286) became the checkout-pattern free-standing rounded card
    (292) with the Continue button (287) outside it; a pending-sync
    chip surfaces till sales still queued for the backend.
  * CheckoutPage headers (11c–11f): the big-title app-bar block replaced
    by the 171-pattern host top-row (chip 304) — bare `interSemi 18.sp
    textPrimary` title on the page surface, no AppBar. ONE back (strip
    section 12, core#125): the floating nav's back-only pill
    (`FloatingNavBack`) replaces the floating PopButton — requires
    base_sdk >= 1.39.0.
  * Create-order pipeline wiring (Ray: "you just need to add scanned
    ones to that pipeline"): every finished sale submits through the new
    `PosOrdersFacade` (`domain/interface/pos_orders.dart`) —
    OFFLINE-FIRST, local drift store first, then the existing SyncEngine
    `order.create` queue (orders_sdk 1.10.0 `PosSaleQueue`); checkout
    never blocks on the network. The sale goes up with the status it is
    IN: 'delivered' in-store, 'ready' send-for-delivery (an offline
    delivery sale HOLDS at Ready locally until the sync drains it).
    Host registration: the installed ADR-005 adapter
    `templates/adapters/manager/pos_orders_adapter.dart`
    (ManagerPosOrdersAdapter); demo builds register the new
    `MockPosOrdersRepository` for zero-backend tours and tests.
  * Credit / partly-paid + send-for-delivery (11g–11i, chips 305–315):
    "Billing to" customer attach (the shop-scoped create-order picker
    reused; REQUIRED before credit unlocks) with the credit-outstanding
    "owes" chip; "Amount paying now" with Full / R0-all-on-credit quick
    actions; the remainder-due banner with the Shop.credit_allowance
    gate line (counter-sale fronting = the item commission); summary
    Paying-now / On-credit split rows; takes/records finish sublabel;
    the delivery address card and "Send for delivery & Finish" (the
    sale enters the NORMAL order queue at Ready). All-on-credit rides
    the merged credit machinery end to end; partly-paid pairs with the
    backend's ONE new piece (create_order `payment_status: 'Credit'` +
    `paid_now` → `Order.pos_paid_amount`, the Paid till Transaction row,
    and the FIFO auto-collect sweeping the remainder). The pay-link QR
    and the offline 6-digit code both carry the PAYING-NOW amount.

## 1.12.0

* POS port (approved strip section 11, frames 11a-11f): the old Spazafy
  manager billing flow rebuilt inside this SDK around the retired Quick
  Receipt app's working ideas, in the current `AppStyle` token language
  (dark-mode compliant throughout - no fixed white/black page surfaces).
  * `templates/pages/manager/billing/billing_page.dart` - the till, now
    manager tab 0 (scan icon; the shell's create FAB shows only on tabs
    1 orders / 2 foods): MobileScanner viewfinder stage with torch,
    pause and a 45s idle auto-pause, 2s scan dedupe, haptic on accepted
    scans; Scan and Add Items (manual search) lanes; cart line cards
    with -/+ steppers, tap-the-quantity decimal edit for weighed kg/L
    units, currency-formatted line totals, per-line remove; item-count
    chip; Clear All; receipt-style summary; Continue carrying the total.
  * `templates/pages/manager/billing/checkout_page.dart` (installed with
    the new `/pos-checkout` route): Cash | QR pay-link toggle, pay-link
    QR card + "I've Scanned" phase gate, dual finish - "Finish without
    Receipt" and the ATOMIC "Print Receipt & Finish" (record only after
    the printer returns) - and the OFFLINE INVERSION: an offline till
    banners and goes straight to 6-digit code entry (the QR stays - the
    customer's phone is online) verified locally by
    `lib/src/manager/utils/pos_pay_verification.dart` (sha256-derived
    6-digit code, widened from Spazafy's 5-digit helper, zero server
    contact), over a `debugConnectivityOverride`-seamed probe
    (`pos_connectivity.dart`).
  * Cart state `lib/src/manager/application/pos_cart/` on base_sdk's
    REAL `ProductData`/`Stocks` family; money cents-rounded at the state
    boundary (18.99×3 + 150×0.75 renders exactly R169.47 - the Spazafy
    float-sum exponential bug is impossible), derived total (Clear All
    can't leave it stale), stable per-order id minted in the notifier.
  * Demo gating: `--dart-define=IS_DEMO=true` routes the till's product
    lookup to this SDK's `MockProductsRepository` ("Demo Product",
    150.00) via the new `PosCatalogRepositoryFacade` registration in
    `ManagerMerchantsDependencies` - headless tours and the standalone
    test harness (`test/pos_*`, `tool/inject_tr_keys.dart`, lms_sdk's
    harness pattern) run with zero backend contact.
  * All five committed Spazafy compile errors are gone by construction
    (crossAxisAlignment; the real model family; `numberFormat(number:)`;
    `bgGrey`/mode-resolving tokens; base_sdk widgets only), plus the
    held-build review findings: the scanner controller is disposed, and
    scans dedupe per physical scan, never per camera frame.
  * Tour fragments pos_scan / pos_cart / pos_checkout added to
    `merchants.tour.yaml`; orders_sdk's queue-selection step moved to
    tab index 1 in the same change (tour-sync rule: screen + fragment
    ship together). New host deps: `mobile_scanner`, `pretty_qr_code`,
    `crypto`.

## 1.11.0

* Added an edit pencil to the wallet card on the manager restaurant tab
  (`templates/pages/manager/restaurant/restaurant_page.dart`, approved
  render 2026-08-28): a top-right `Remix.pencil_line` IconButton stacked
  over `BaseWalletCard` in `MerchantWalletSection`, opening the shop-edit
  flow via the exact same `EditRestaurantModal` bottom-sheet invocation as
  the "Restaurant settings" sections row. Overlaid rather than passed
  through the card's `actions` parameter because base_sdk renders
  `actions` as a bottom strip, not top-right.

## 1.10.0

* Rebuilt the manager restaurant tab (`templates/pages/manager/restaurant/
  restaurant_page.dart`) as a host of base_sdk's generic profile page
  (approved profile-host design, section 7, 2026-08-28): standard host
  header, no cover art (the `ShopBanner` sliver is retired from the page;
  the widget file stays installed but unreferenced), and every old content
  block re-registered as a profile section in the old order —
  `merchants.shop_info`, `merchants.working_hours`, `merchants.wallet`,
  `merchants.sections`, plus the `merchants.open_toggle` top-row action
  (the old floating Open/Closed toggle) and a `base.footer` override adding
  the old bottom-nav clearance. The hand-built balance box is replaced by
  base_sdk's `BaseWalletCard` in display-only form (`actions: const []`,
  no history arrow) over the same cached shop-JSON seller wallet source.
  The old floating logout button maps to the host's sign-out affordance
  (registry `onLogout`, the LogoutModal's confirmed branch). Tab wiring is
  untouched: `main_page.dart` still imports the page directly and it
  declares no route. Requires base_sdk >= 1.32.0.

## 1.9.4

* Routed the broken direct `/api/method/paas.api.*` call sites through
  base_sdk's universal platform gateway (`PlatformGateway`, fleet rule
  2026-08-15): shops repository (`api.shop.search_shops`/`get_shops`/
  `get_nearby_shops`/`get_shops_by_ids`/`create_shop`/`get_shops_recommend`,
  cross-module `api.cart.join_order`, `api.delivery.check_delivery_zone`,
  `api.story.get_story`, `api.tag.get_tags`, `api.product.get_suggest_price`)
  and the offline shop-create sync handler (`api.shop.create_shop`,
  idempotency header preserved). Fixed payload keys that never matched the
  backend kwargs: get_shops_by_ids `shop_ids`, join_order
  `cart_id`/`user_name`, create_shop wrapped in `shop_data`. Registered the
  missing `api.seller_operations.get_seller_sections`/`get_seller_tables` and
  `api.seller_product.create_product` whitelisted-method keys in
  merchants/frappe/manifest.json. Recorded endpoint gaps
  (get_shop_by_uuid/get_shop_branch/get_pickup_shops) are untouched.

## 1.9.3

* Freezed 3 follow-through (PR #28 missed the templates dir): the installed
  `merchants_adapters.dart` template now imports
  `package:base_sdk/src/handlers/api_result.dart` directly so its
  `ApiResult.when` call site resolves against freezed-3 base_sdk. No behavior
  change.

## 1.9.1

* Sliced `manager/infrastructure/models/` into the canonical `data/` and `response/` subfolders: moved `sections_tables.dart` to `models/data/` and `my_shop_response.dart` to `models/response/`. Updated all imports. No API changes.

## 1.9.0

* Driver migration S-D6: adopted paas_driver's intro-story block (`driver/application/story` + story page + `/story` route). See manifest comment for details.
