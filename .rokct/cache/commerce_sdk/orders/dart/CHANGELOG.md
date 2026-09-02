## 1.15.0

* `DemoSellerOrdersRepository` — demo data behind the manager's two order
  screens. `ManagerOrdersDependencies.register` now selects it over
  `SellerOrdersRepository` under `--dart-define=IS_DEMO=true`, the same
  `AppConstants.isDemo` ternary merchants_sdk's POS seams and products_sdk's
  catalog facades already use. Nothing about the production path changed.
  * WHY: the guided tour runs the app in demo with zero backend calls, so
    the `order_queue` and `order_history` stills were capturing empty
    states — a brand-new shop's truth, but not a marketing screenshot.
  * WHAT IT SERVES: a seeded shift of seven fictional orders across
    new / accepted / ready / delivered, with plausible rand totals and
    times that walk backwards through the trading day. Counts for every
    board column are computed off the live overlay, so the pills agree with
    the rows actually served. History is the delivered + canceled pair.
  * WRITES are acknowledged in memory: a status move, a collect-in-person
    conversion or a POS sale sticks for the rest of the session and resets
    on the next launch (zones_sdk `DemoDriverDeliveryZonesRepository`
    overlay convention). No HTTP client is ever constructed and nothing
    leaves the device.
  * The seeded dishes deliberately match products_sdk's and kitchen_sdk's
    demo menus, so the queue, the menu and the kitchen tell one story.
    Duplicated rather than shared — ADR-005 keeps these SDKs free of
    cross-SDK imports, and a handful of dish names is cheaper than a seam.
* Tour fragment: the demo-grounding note now records that both steps are
  demo-backed. `PosProductsRepositoryFacade` is still un-gated, so the POS
  create-order flow stays deliberately un-toured.

## 1.14.0

* Saved-card payments name the CARD, not a credential. `Saved Card.token`
  is the gateway reuse credential — presenting it to the gateway charges
  that card again — and pay confined it to a Frappe `Password` field
  (pay#46), so it stopped travelling to clients at all. Every saved-card
  path in this SDK now follows the handle:
  * REPEATING / AUTO ORDERS — the one that actually broke.
    `process_repeating_orders` in `orders/frappe/src/tenant/tasks.py`
    fetched the Saved Card and passed `card.token`. Under a `Password`
    column that reads back as a row of asterisks, which resolves to no
    card, so the charge was REFUSED before any gateway call: repeating
    orders quietly stopped paying. It now passes
    `saved_card=ro.saved_card` — the docname the Repeating Order already
    stores — and the `frappe.get_doc` that existed only to reach the
    credential is gone. `promotions/frappe/src/tenant/tasks.py` is a
    byte-identical composed copy and carries the same change.
  * `order_check.dart` passes `_selectedCard!.id` — the Saved Card
    docname — to `processTokenPayment`, where it passed
    `_selectedCard!.token`.
  * `auto_order_notifier.dart` needed NO change: its `savedCardId`
    already IS the docname (the picker's value is `card.id`), which the
    old API refused and the new one accepts. It is now commented so the
    next reader does not "fix" it back.
* Tests: `orders/frappe/tests/test_repeating_order_saved_card_charge.py`
  and the identical suite under `promotions/frappe/tests/` (8 tests
  each; 3 of the 8 fail against the pre-change task). The headline test
  is end to end — a due repeat order on a saved card is created, charged
  once against the docname, and produces no payment-failed notification
  — with guards for an unknown card, another user's card, the
  ringfenced-wallet path, and a saved-card method with no card. The
  bench script `tests/verify_auto_order_flow.py` took
  `tokenize_card(...)["token"]`, which can now only KeyError; it takes
  `["name"]` and tops up with `saved_card=`. No real credential value
  appears in any test, fixture or message.
* REQUIRES base_sdk >= 1.50.0 and a backend carrying pay#46. Against an
  older backend a saved-card charge is REFUSED without being made — the
  failure mode is a payment that does not happen, never a wrong one.
* VERSIONING NOTE: the `order_check.dart` half shipped in commerce#92
  with no orders_sdk bump (that PR was deliberately held to two files),
  so it went out under 1.13.0. This entry covers it as well as the
  backend half landed here.

## 1.13.0

* DELIVERY COLLECTED IN PERSON (approved design strip section 43, frames
  43a tablet / 43b the confirm guard / 43c phone / 43d the card states /
  43e offline). The customer turns up at the counter for an order she
  placed for delivery. Ray's policy, unbent: the goods are NEVER
  withheld and never forfeited — what changes is only where the delivery
  fee ends up.
  * A new **collected-in-person** block the manager order detail mounts
    directly under its price block, and which renders NOTHING unless the
    order is a delivery order still waiting to be handed over: the
    deliveryman row (**811** dashed and faint when nobody has been
    dispatched, **812** solid and cyan with an `ON A CALLOUT` tag when
    somebody has — this row is what decides the branch), the single
    primary action lane **813** ("Customer is here — convert to pickup",
    one verb, a bag glyph and never a truck), the outcome named BEFORE
    the tap (**814** green "the fee goes back to the customer's wallet" /
    **815** amber "the fee is kept — it covers his callout"; ONE
    component with two tints, never both on screen), and Ray's till line
    **816** verbatim.
  * The confirm guard **817**/**818**/**819** (the chip-768 pattern —
    the consequence before the tap, never a snackbar after it): four
    ledger rows, one per thing that actually moves — Goods, Delivery
    type, Delivery fee, Driver task — so the two branches can never be
    confused. The affirmative button is deliberately the WIDER one:
    handing the goods over is never the risky choice.
  * The delivery-type chip **810** lifted out of the board card into the
    detail, and the two converted board-card states **820**/**821**: the
    struck fee and the dropped total are the visible proof of the
    conversion's money write, so fee-returned versus fee-kept is legible
    from the card alone without opening the order. `get_seller_orders`
    now serves `delivery_type` and `delivery_fee` (it did not, so the
    board card's type chip had nothing to render) plus the two new
    conversion fields.
  * OFFLINE (43e) the lane stays **enabled** and is relabelled in place —
    "Hand over now — convert when back online" — because refusing to give
    the customer her goods is the one thing that must never happen. The
    branch is undecidable offline (driver assignment and wallet balance
    are both server state), so 814/815 are replaced by a neutral note and
    the conversion is queued through a new `order.collect_in_person` sync
    handler. The endpoint is idempotent, so the replay converts nothing
    twice; a backend refusal parks in Sync issues rather than silently
    reverting a hand-over that already happened.
  * ONE call, never a client-orchestrated sequence:
    `SellerOrdersRepositoryFacade.convertDeliveryToCollected` hits the one
    new atomic seller endpoint (merchants `convert_delivery_to_collected`,
    merchants_sdk 1.20.0). The settlement ordering that keeps the driver
    from being paid the delivery fee twice lives inside that one
    transaction, where a dropped connection cannot get between the two
    writes.
  * Pickup now reads as a BAG on the board card's type chip (it read as a
    walker), so a converted card and the action that made it are
    recognisably the same thing.

## 1.12.0

* ORDER HISTORY adopts the standard list language (approved design strip
  frames 38a + 38d, Ray 2026-08-30 12:23Z: "33 list language = STANDARD
  for all lists"). The shipped page was an undesigned white `ListView`
  with two floating buttons (a `PopButton` bottom-start and an equalizer
  filter FAB bottom-centre).
  * New `src/manager/presentation/history/order_history_list.dart`: the
    list body in the 33 dress — the header count pill carrying the
    shipped "There are N orders" line (chip 700), the shipped
    `FilterScreen` date range re-homed from the FAB to a header utility
    (chip 358), history's real statuses as the 362/363 tab bar, the
    board's own order card carried to a FINISHED order (chips 352/353/354
    — progress chip full at 100%, clock FROZEN at `updatedAt` so the card
    reads how long the order took), and "View more · +N" (chip 356).
  * THE STATUSES, disclosed: the shipped `fetchHistoryOrders` call asks
    `get_seller_orders` for `delivered` only — the `statuses[]` filter is
    a recorded endpoint gap, so one call cannot fill both tabs. The
    Delivered / Cancelled tabs are therefore fed by the board's own
    per-status queues (`deliveredOrdersProvider` /
    `canceledOrdersProvider`), which already page and count each status
    against the same endpoint. Real counts, real paging, no new endpoint.
  * The installed `order_history.dart` is now the host shell only: at
    plane widths the list declares TWO planes and a tapped order's
    details push into the LAST plane as a PANE (the 12:02Z sheet fork),
    with the corner back pill at the bottom-END (chip 347); on one plane
    it is the same shape with the shipped `OrderDetailsModal` bottom
    sheet, unchanged (frame 38d).
  * RECEIPT REPRINT in the order detail — Ray's amendment on approving
    38a ("wired to the till receipt path"). New narrow seam
    `src/manager/domain/interface/order_receipt.dart`
    (`OrderReceiptFacade` + `resolveOrderReceiptFacade()`), because
    orders_sdk must not import the SDK that owns the printer (ADR-005);
    the manager host binds it to merchants_sdk's `PosReceiptPrinter` via
    the new `ManagerOrderReceiptAdapter` in the installed
    `orders_adapters.dart`. No printer wired means no button — the detail
    never offers an action that cannot work.
  * Requires base_sdk >= 1.46.0 (the list language).
  * Test: `order_history_list_test.dart` — the two independently counted
    and independently paged status tabs, the 700 pill as their sum, the
    finished card at 100% with its frozen clock, and View-more paging the
    ACTIVE tab only.
## 1.11.0

* Manager orders board upgraded to the APPROVED design (Ray 2026-08-29:
  12:10Z "31b adopt 31a but uses our base theme"; 13:06Z "33a is
  approved"; 13:53Z "approved: 34a , 33d,33b"). The board machinery moved
  from the excluded templates/ into analyzable, tested package code at
  `lib/src/manager/presentation/board/`:
  * SEVEN colour-coded columns — New / Accepted / **Cooking** / Ready /
    On the way / Delivered / Cancelled — with coloured count pills,
    per-column refresh and "View more · +N" paging; far columns scroll
    sideways (POS 235-wide columns kept). New `BoardStatus` axis maps to
    base_sdk's `OrderStatus` where one exists; `cooking` (absent from the
    shared enum) rides the new `rawStatus` seam on
    `SellerOrdersRepositoryFacade.getOrders`/`updateOrderStatus`, with a
    new cooking queue provider and `cooking_orders_count` statistic
    parsing (falls back to the loaded length until the backend sends it).
  * Cards carry the full POS feature set in the dark base theme: 1s-ticking
    elapsed clock + time range **frozen once the order reaches Ready**
    (`OrderClock`), order-type chip with per-status progress fill
    (0/20/40/60/80/100%) and type glyph, map-pin affordance on delivery
    cards (`BoardMapDialog`), POS drag treatment (tilt/shadow/brand
    border on lift).
  * SMART SKIP (POS board_view.dart:266-273): a pickup dragged onto
    On the way lands in Delivered — with the approved airborne treatment
    (On the way dims, Delivered lights a "drop here" slot, hint banner).
  * Header: board/list toggle, date-range filter (threads from/to through
    every queue notifier into `get_seller_orders`), and the new-order
    sound bell with activity dot. The POS played a bundled wav via
    audioplayers; the fleet carries no audio dependency, so the chime uses
    the engine's `SystemSound` (no package, no asset).
  * Waiter rule carried over: a waiter login hides the On-the-way column
    (and tab).
  * Phones get the POS's LIST MODE per approved 33b: colour-coded status
    tab row with counts over a single card list.
  * 33d click behaviour: on wide windows the workspace is hosted in
    base_sdk 1.43.0's plane model (`OrdersBoardPlaneFlow`): the board
    declares `PlaneSpan.all`; tapping a card pushes the order detail with
    the DEFAULT one-plane claim into the LAST plane, the board yields and
    compresses, and the nav folds to the corner `FloatingBackPill`. On
    phones the detail stays the modal bottom sheet — the plane model's
    own one-plane degradation. The detail plane hosts the existing
    `OrderDetailsModal` in a pane-local navigator so its post-action
    `Navigator.pop` folds the plane, never the workspace.
  * The legacy four-icon-tab phone layout is retired from
    OrdersHomePage; the old per-status body widgets remain installed but
    unused (removal deferred).

## 1.10.0

* POS till sales feed the EXISTING seller create-order pipeline,
  offline-first (Ray's rulings 2026-08-28, approved strip 11g–11i). New
  `PosSaleQueue` (`infrastructure/services/pos_sale_queue.dart`): the
  finished sale is written to the local drift store FIRST
  (`ManagerOrdersLocalStore.putPending`) and enqueued as the same
  `order.create` outbox op `OrderCreateSyncHandler` already drains —
  checkout never blocks on the network; the backend's `@idempotent` +
  `offline_uuid` dedupe (the till's stable POS order id) makes retries
  safe. The body is the canonical backend `create_order(order_data)`
  contract (`shop`/`user`/`order_items[].product`) carrying the POS
  additions: the sale's REAL `status` (an in-store sale is 'delivered';
  a packed send-for-delivery sale is 'ready' and an offline one HOLDS
  there until the sync drains it) and the credit / partly-paid pair
  (`payment_status: 'Credit'` + `paid_now`). `PosSaleQueue.pendingCount`
  backs the billing page's pending-sync indicator.
* `ManagerOrdersLocalStore.toOrderData` no longer hardcodes queue rows to
  'new': the row carries the ACTUAL status the stored create body holds
  (legacy bodies without one keep 'new').

## 1.8.0

* 18+ (adults only) checkout support. `get_calculate` now answers the
  additive `contains_adult_items` / `requires_birth_date` flags (parsed by
  base_sdk's `GetCalculateModel`), and the order sheet's `_createOrder` gains
  an age gate mirroring the phone-gate precedent: when the cart holds an
  adult item and the profile has no birth date, a date-of-birth bottom sheet
  (`AgeVerifyModal`) collects it, writes it through the universal platform
  gateway (`api.user.update_user_profile`, `birth_date` "YYYY-MM-DD"), then
  re-runs calculate + order creation. The backend `create_order` failure
  markers `AGE_VERIFICATION_REQUIRED` and `UNDERAGE_PURCHASE_BLOCKED` are
  mapped in the customer orders repository onto distinct friendly,
  translatable messages (wire-key strings, declared in the manifest's
  customer tr_keys). Manager POS orders are exempt server-side (face-to-face
  ID check), so the POS flow is untouched.

## 1.7.1

* Routed the broken direct `/api/method/paas.api.*` call sites through
  base_sdk's universal platform gateway (`PlatformGateway`, fleet rule
  2026-08-15): cart (`api.cart.*` — get/add/remove/change_status/delete_cart/
  delete_user/get_cart_in_group), customer orders (`api.order.*` —
  create/list/details/review/cancel/get_calculate), coupon
  (`api.coupon.check_coupon`), parcel (`api.parcel.*` — review/types/
  calculate_price/create/list/single), seller POS create-order + offline sync
  handler (`api.order.create_order`, idempotency header preserved), seller
  shop payments (`api.seller_transactions.get_seller_shop_payments`), and the
  manager POS adapters (`api.seller_operations.get_seller_sections`/
  `get_seller_tables`, keys registered in merchants/frappe/manifest.json).
  Fixed payload keys that never matched the backend kwargs: check_coupon
  `code`/`shop_id`, get_calculate `coupon_code`, tip_process `tip_amount`,
  get_driver_location `driver_id`, add_parcel_review `parcel_id`/`review`,
  calculate_price nested `address_from`/`address_to`. Alias-only paths
  (`paas.api.repeating_order.*`, `paas.api.user.*`,
  `paas.api.payment.create_order_transaction`) and recorded endpoint gaps
  are untouched.

## 1.6.2

* Freezed 3 follow-through for the pockets PR #28 missed: `OrdersBoardState`,
  `CanceledOrdersState`, and `DeliveredOrdersState` migrated to the
  `abstract class` form, and their notifiers given the direct
  `package:base_sdk/src/handlers/api_result.dart` import that brings the
  legacy `when`/`map` extensions into scope. No behavior change.

## 1.6.1

* Rewrite the last three double-segment API call paths in
  `orders_repository.dart` to their registered composed manifest aliases
  (same client-side fix direction as pay PR #9 and the 1.5.2
  `create_order_transaction` rewrite):
  `paas.api.payment.payment.initiate_<gateway>_payment` →
  `paas.api.payment.initiate_<gateway>_payment` (pay wallet manifest
  registers the flutterwave/paypal/paystack initiate aliases), and
  `paas.api.user.user.create_order_refund` /
  `paas.api.user.user.get_user_order_refunds` → `paas.api.user.…`
  (users manifest aliases). The old double-segment paths 404 on composed
  backends. No behavior change beyond the URLs; the documented-gap
  endpoints (`get_seller_shop_payments`, templates' `search_users` /
  `create_walk_in_customer`) are intentionally untouched.

## 1.6.0

* Wide-screen (POS-style) layouts for the manager order pages, gated on
  base_sdk >= 1.11.0's adaptive primitives (`AdaptiveShell`, `SplitPane`,
  window-size classes — core PR #35 must land first). Compact/medium windows
  are byte-for-byte the old phone flows.
* Order queues: on expanded windows `orders_home_page` swaps the four-icon
  tab bar for a six-column kanban board (new / accepted / ready / on the way /
  delivered / canceled — POS's `board_view` minus its cooking column). Cards
  long-press-drag forward along the state machine using Flutter's own
  `LongPressDraggable`/`DragTarget` (no `drag_and_drop_lists` dependency, no
  host pubspec change); a drop calls the same `updateOrderStatus` repository
  call as the details modal's swipe button (new `ordersBoardProvider`), then
  refreshes the source and target columns. The four active columns reuse the
  existing per-status providers; new `deliveredOrdersProvider` /
  `canceledOrdersProvider` back the two history columns (manifest gains the
  `delivered`/`canceled` tr_keys for their headers).
* Create order: on expanded windows the product grid and the cart render
  side-by-side (`SplitPane`, POS `main_page` style). The cart body moved from
  `order_page.dart` into a shared `OrderPane` widget that both the pushed
  phone route and the embedded pane use on the same cart/payment providers;
  the embedded pane recalculates when the cart's stocks change instead of on
  route push.
* `NewOrdersNotifier` only calls `requestRefresh()` when the pull-to-refresh
  controller is attached to a scroll view — on the board no SmartRefresher
  exists and the unguarded call would throw.

## 1.5.2

* Offline POS sale payments: `OrderCreateSyncHandler._createTransaction`
  now sends an `X-Idempotency-Key` header (`<op.id>:txn` — derived from
  the same op id as the order-create call but deliberately distinct, so
  the two creates never share a key). Pairs with the pay-side
  `create_order_transaction` endpoint landing (called via its composed
  manifest alias `paas.api.payment.create_order_transaction`); the two
  call sites that used the unregistered 4-segment
  `paas.api.payment.payment.create_order_transaction` path are rewritten
  to the alias (same client-side fix direction as pay PR #9).
  The contract doc's `createTransaction` row is flipped from gap to done
  and the stale "Recorded gap" comment in `seller_orders_repository.dart`
  is updated. Best-effort semantics of the transaction call unchanged.

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
