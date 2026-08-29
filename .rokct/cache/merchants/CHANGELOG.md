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
