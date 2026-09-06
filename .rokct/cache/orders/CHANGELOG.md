## 1.20.0

THE MANAGER WINDOW ON THE LAUNCHER CANVAS - approved design strip frames
53f and 53l (Ray 2026-09-01, "all launcher screens approved"): manager
mode, the same screen and the same binary as driver mode, and the takings
figure deliberately absent.

* New `ManagerLaunchWindow` (`lib/src/manager/presentation/launcher/
  manager_launch_window.dart`), the content of the launcher's manager
  window (chip 1256): "Orders to accept", the "Waiting on you" count of
  orders in the `new` column, and one Open orders action that opens the
  manager app. The launcher owns the chrome and the placement (53g); only
  the ranking and the payload differ from 53e (chip 1258).
* NO TAKINGS (chip 1289): Ray ruled earnings and balance off the canvas on
  53e; sales figures are money by the same reasoning, so today's takings
  are omitted here as the frame's labelled extension of that ruling -
  `ManagerLaunchQueue` carries a count and no amount, and nothing in the
  window formats a currency. One word reverses it.
* DATALESS BACK SEAT (chip 1288, ruled: "data dont show on launcher when
  another mode is active"): `ManagerLaunchWindow.dataless` renders the Open
  orders affordance alone, so the window is useful and tappable without
  data. On 53l, where only the manager app is installed, the launcher
  derives one mode and draws no driver row at all (chip 1284) - that is the
  launcher's derivation (53k), nothing here decides it.
* Data comes through the same facade the manager order board reads
  (`SellerOrdersRepositoryFacade.getOrders(status: open)`: the statistic's
  `new_orders_count`, else the page's length), which in an IS_DEMO build is
  the seeded `DemoSellerOrdersRepository`; a composition with no facade and
  no demo seed, or a backend that does not answer, draws the headline and
  the action without a count and never throws.
* manifest.json 1.19.1 -> 1.20.0: top-level `integrations` inject the
  window under launch_sdk's `// @launcher-windows` marker and its import
  under `// @launcher-windows-imports` (productivity_sdk's glance pattern;
  requires launch_sdk >= 1.4.3, declared in `_comment_requires`); top-level
  `tr_keys` for the window's copy (`orders_to_accept`, `waiting_on_you`,
  `open_orders`) and the back-seat title (`manager`). The mode line and
  the "set from the app found" status (chip 1257) are the launcher's
  (53k); nothing here names a package.
* Tests: `test/manager_launch_window_test.dart` covers the populated,
  count-less and dataless states, the no-currency exclusion, the loader
  against the demo seed and against a facade that fails, and the manifest
  wiring.

## 1.19.1

* Fix: drop `const` on Manager shipping/select-address route constructions
  that became non-const in 1.19.0 (compile break in every shell installing
  orders_sdk manager pages).

## 1.19.0

* WALK-IN ORDER FLOW ON PLANES — approved design strip section 37, frames
  37a–37e (Ray 2026-08-30 12:23Z "build authorized"; decision (a) locked:
  /order dissolves into the cart pane at plane widths). The shipped
  create-order chain (commerce#79: /order-products → /order →
  /shipping-address → /select-address → /delivery-time) is re-laid in the
  plane language on the SAME providers — composition only, no data change.
  * New `src/manager/presentation/walk_in/walk_in_plane_flow.dart`:
    `WalkInPlaneFlow`, the PlaneHost stack of the cascade — the orders
    board as the yielded origin (`PlaneSpan.all`), the walk-in page
    claiming TWO (products | cart; yielded to one plane at the fold it
    compresses to its products column, the cart one Back away), the
    product-details pane (the 12:02Z sheet fork: FoodDetailsModal is a
    sheet on the phone, a pane at plane widths), /shipping-address and
    /delivery-time as DEFAULT one-plane steps in the LAST plane, and
    /select-address claiming ALL with `allowNeighbors: false` (the 19b/20b
    map ruling). The host's corner Back pill (347, bottom-END) pops the
    NEWEST step; at the root it exits the route and the board re-expands.
  * New `src/manager/presentation/walk_in/walk_in_board_rail.dart`:
    `WalkInBoardRail` (chip 675) — the ALL-declaring board compressed to a
    one-plane rail: colour-coded column heads with the board's own count
    pills over two-line mini cards (number + total, customer + payment),
    read from the queue providers the workspace already fetched. Empty
    columns are not drawn.
  * `templates/pages/manager/create_order/create_order_page.dart` is the
    host shell: two or more planes (`PlaneHost.planeCountFor`, the
    BoardLayoutSwitch rule) build the flow with the `${package}` step
    widgets; one plane is the shipped compact page (37d) with the shipped
    pop | Ordering FAB pair re-housed per the two-state rule — "Ordering ·
    total" (690) at the START pushing /order, the corner Back pill (347)
    at the END. The old `AdaptiveShell` + hard-coded `SplitPane` are gone:
    products | cart is now produced by the declaration. Header: the
    171-pattern bare title ("Walk-in order"); canonical 318 search field
    (with the filter suffix) + 349 category chips over the shipped
    OrderFoodItem rows (678/679/680).
  * `order/widgets/order_pane.dart` (681): grows `onNext` (the plane push;
    null keeps the route push) and the calculated subtotal row (684,
    "Subtotal · N items" — getCalculate already runs there; totals stay on
    /delivery-time). `order/order_page.dart` (phone only, 37d's push
    chain): Next at the START, corner Back pill at the END.
  * `shipping/shipping_address_page.dart` (686–689): grows `onNext` /
    `onSelectAddress` — hosted in planes they push into the planes and
    Next docks at the pane's foot under the "Shipping" title; on the phone
    route Next at the START, corner pill at the END. The /select-user,
    /select-section, /select-table pickers stay pushed routes (list-picker
    family, group J — not framed in 37).
  * `shipping/address/select_address_page.dart` (691–695): grows
    `onClose`; Confirm location writes the pick into 689's field and pops
    the plane (centred on its own when hosted — the host's pill holds the
    END corner) or the route (Confirm at the START, pill at the END).
  * `shipping/details/delivery_time_page.dart` (696–699): "Place order"
    title, the button becomes "Place order · total" with the offline-queue
    line under it (the shipped orderQueued path told in one line: the
    order queues on this device and syncs); hosted it docks under the
    cards, on the phone it sits at the START with the corner pill at the
    END. popUntilRoot still ends the flow under either width.
  * Surfaces of the five pages move to `AppStyle.surfaceDark` with
    `textPrimary` ink (the tokens every plane-hosted sibling uses); the
    shipped row and card widgets (OrderFoodItem, FoodStockItem, the
    delivery-type / payment cards) keep their shipped dress — their dark
    redress belongs to the dark-mode fleet wave, not to this layout.
  * Manifest (app_type.manager.tr_keys): `walkInOrder`,
    `searchWalkInProducts`, `orderItems`, `shipping`, `placeOrder`,
    `offlineOrderQueuesAndSyncs`. No new base_sdk requirement — the
    1.43.0 plane model 1.11.0 already requires.
  * Test: `walk_in_plane_flow_test.dart` — 1280 (rail | products | cart;
    details pane in the last plane; shipping in the last plane with the
    board off stage; the map ALL and alone; the pill popping one step at
    a time down to the route exit), 800 (the two-plane claim fills the
    fold, no rail; shipping compresses the walk-in to its products column)
    and 393 (the newest step is the whole screen).

## 1.18.3

* fix(demo): `MockOrdersRepository`'s seeded customer order trades in rand
  (Ray 2026-09-04 13:13Z "in fact you should go check all tour of the app
  shells"). Its `CurrencyModel` was the one USD/`$` left in the fixtures
  (id `1`, symbol `$`, title `USD`) while `DemoSellerOrdersRepository` and
  the rest of the demo seed are ZAR; it is now id `ZAR`, symbol `R`, title
  `South African Rand`. Total (45.00), status, shop and lines unchanged.
  Pairs with merchants_sdk 1.28.2, which seeds the same rand into
  LocalStorage for the manager till.

## 1.18.2

* fix(demo): demo order numbers stop announcing themselves as demo (Ray
  2026-09-03 21:45Z "demo in text or demo data is not needed").
  `DemoSellerOrdersRepository`'s seven seeded orders drop the `DEMO-`
  prefix (`DEMO-1041` … `DEMO-1035` -> `1041` … `1035`) and orders the
  POS creates in-session follow (`DEMO-${_nextId++}` -> `${_nextId++}`,
  still counting from 1042), so the board card, the collect sheet and the
  history list print "№1041" instead of "№DEMO-1041". kitchen_sdk 1.4.1
  makes the identical change to its tickets so the two fixtures stay in
  sync. Customers, lines, prices, statuses, times and counts are
  unchanged.
* fix(demo): the customer-side `MockCartRepository`'s group cart renames
  "Demo Cart" -> "Thandi Mokoena" (the first seeded customer), which is
  what the order screen's cart list prints; id, uuid and lines unchanged.

## 1.18.1

* fix: drop const on AppStyle.primary (getter since core #105) in six
  order-history/status widgets so composed shells compile.
  `order_status.dart:133,150,168` and `promo_code.dart:130` lose the `const`
  on `BoxDecoration(color: AppStyle.primary)`, `rating_page.dart:116` on
  `Icon(..., color: AppStyle.primary)`, and `OrderStatusItem.bgColor`
  (`order_status_item.dart:28`) becomes nullable with `?? AppStyle.primary`
  at the use site, since a const constructor's default value must be a
  constant. Behaviour unchanged; the customer order screens these widgets
  sit on were first wired into composed apps as routes in 1.16.0, which is
  when the invalid-constant errors started breaking paas_customer /
  supacharge composes.

## 1.18.0

* ORDER HISTORY's plane flow moves into the package (approved frames 38a +
  38d, Ray 2026-08-30 12:23Z; the bare trailing plane is the 10:47Z rule
  frame 38b draws for the sibling notifications list). The behaviour
  itself shipped in 1.12.0 — the fleet review of the tablet store stills
  (2026-09-02, still 13-order_history) read the installed page as "adaptive
  columns, no PlaneHost"; on main it has been `ListDetailFlow` since
  2026-08-31 (commerce #92), and the still's two full-width columns with
  no detail are exactly the list holding both planes of the 800-logical
  fold with nothing tapped. What was missing was a test of that at each
  width, which the installed template (excluded from analysis, `${package}`
  imports) could not carry.
  * New `src/manager/presentation/history/order_history_plane_flow.dart`:
    `OrderHistoryPlaneFlow` (the `ListDetailFlow<HistoryDetail>` wiring —
    the list declares TWO, a tapped order's details push into the LAST
    plane with the default one-plane claim, the corner back pill pops the
    pane) and `OrderHistoryDetailPane` (the pane-local navigator whose
    sentinel folds the plane when the detail pops), both lifted verbatim
    from the installed `order_history.dart`, which is now the host shell
    only: it hands the shipped `OrderDetailsModal` to the pane and keeps
    the 38d phone branch (one column, bottom sheet) unchanged.
  * Test: `order_history_plane_flow_test.dart` — 1280 (list over planes
    1–2 in two columns, the third plane BARE, tap → detail in plane 3,
    pill pops, spread restored), 800 (list fills the fold, tap → list
    compresses to one column beside the detail, second tap swaps the pane,
    back restores) and 393 (the host's `AdaptiveShell` picks the compact
    branch: one column, the tap handed to the sheet, no plane flow).

## 1.17.1

* `pubspec.yaml`: `flutter_slidable` pin `^3.1.0` -> `^4.0.3`. The two
  manager-only templates (`templates/components/manager/food_stock_item.dart`,
  `templates/pages/manager/create_order/order/widgets/order_pane.dart`) are the
  only importers; paas_manager's host pubspec pins `^4.0.3` because 3.x cannot
  build on Flutter >= 3.38, so the disjoint ranges made every manager lane that
  re-extracted orders_sdk >= 1.16.0 fail version solving ("manager depends on
  flutter_slidable ^4.0.3 ... version solving failed"). The templates use only
  API unchanged in 4.x (`Slidable`, `ActionPane`, `ScrollMotion`,
  `SlidableAction`, `Slidable.of`, `SlidableAutoCloseBehavior`). Driver and
  customer hosts are unaffected (`lib/` never imports it).

## 1.17.0

* Tablet fixes 2026-09-02 (manager tablet review against the approved
  renders). `BoardLayoutSwitch`
  (`lib/src/manager/presentation/board/board_layout_switch.dart`): the manager
  orders workspace's installed `orders_home_page.dart` template now shows the
  board (approved frame 33a) when `PlaneHost.planeCountFor(maxWidth) >= 2`,
  measured from the page's own constraints, instead of `AdaptiveShell`'s
  840 px expanded window class - the plane model already grants an 800 px
  tablet two planes, so the board follows it. Test:
  `board_layout_switch_test.dart`.

## 1.16.1

* Demo seed data (`--dart-define=IS_DEMO=true`), `MockOrdersRepository`: the
  active-order card's shop is "Nonna's Pizzeria" (matching merchants_sdk's
  demo shops) rather than "Demo Pizza Shop", and its logo is base_sdk's
  inline `DemoImages` rather than a public placeholder host - the customer
  home's active-order strip captured that logo as a broken-image glyph.

## 1.16.0

* Fix-wave 2026-09-02 (Dart SDK audit, groups G4/G6/G3/G1). Every call that
  still hit a dead per-method `/api/method/paas.api...` URL or a Laravel-era
  `/api/v1/...` path now goes through the universal gateway
  (`POST /api/v1/method/rokct.platform.api`, `{cmd, payload}`) with the cmd
  the owning module's frappe manifest whitelists:
  * customer `CartRepository.insertCartWithGroup` ->
    `api.cart.insert_cart_with_group {cart}`; `OrdersRepository.process` ->
    `api.payment.initiate_{flutterwave|paypal|paystack}_payment {order_id}`
    (any other gateway name is refused client-side with a 400-shaped failure
    instead of a router 404 - the wallet half has no `initiate_*` for it);
    refunds -> `api.user.create_order_refund {order, cause}` /
    `api.user.get_user_order_refunds {page}`; repeating orders ->
    `api.repeating_order.{create,pause,resume,delete}_repeating_order`
    (`createAutoOrder` always sends the required `cron_pattern`, defaulting
    to daily); `ParcelRepository.process` ->
    `api.payment.initiate_<provider>_parcel_payment {order_id}` and
    `createTransaction` -> `api.payment.create_order_transaction`.
  * manager `SellerOrdersRepository` -> `api.seller_order.get_seller_orders`
    / `get_seller_order_details` / `update_seller_order_status`,
    `createTransaction` -> `api.payment.create_order_transaction`, and
    `getCalculate` -> `api.product.order_products_calculate {products: [...]}`
    (a JSON list replaces the bracket-style query). `PosProductsRepository`
    -> `api.seller_product.get_seller_products` / `get_seller_categories` /
    `get_product_details {product_name}` with `limit_start` paging.
  * `OrderCreateSyncHandler` (the POS offline outbox) replays the payment
    transaction through the same gateway cmd, keeping the
    `X-Idempotency-Key` header via `PlatformGateway.call(options:)`.
  * `templates/adapters/manager/orders_adapters.dart`: the section/table
    pickers send `limit_start`/`limit_page_length` (the server takes no
    `page`, `search` or `shop_section_id`).
* Customer routes recovered (fix-wave route map): `app_type.customer` now
  declares `/order`, `/orderScreen`, `/order_progress`, `/parcel_page`,
  `/info_screen`, `/parcel_list_page`, `/parcel_progress_page` with shells in
  `templates/routes/orders_customer_route_pages.dart`, and fills base_sdk's
  `pushOrdersListRoute` / `replaceOrdersListRoute` / `pushOrderRoute` /
  `pushOrderProgressRoute` / `pushParcelRoute` / `pushInfoRoute` /
  `replaceInfoRoute` / `pushParcelListRoute` / `replaceParcelListRoute` /
  `pushParcelProgressRoute` seams. Before this every one of those calls hit
  the host's `noSuchMethod` StateError.
* `flutter_slidable: ^3.1.0` added to pubspec (two manager templates import
  it; pinned from the pre-fork POS pubspec).
* FLAGGED, not built (no server method - owner decision needed):
  `CartRepository.startGroupOrder`, and the walk-in customer create in
  `orders_adapters.dart`. Both keep failing visibly on their dead path with
  a `TODO(fix-wave 2026-09-02)` at the site. `ParcelRepository.createTransaction`
  is routed but wallet's `create_order_transaction` only resolves Order
  docnames today (parcels are refused server-side).
* Tests: `test/gateway_cmd_test.dart` (cmd + payload per rewritten call,
  over a recording HttpService; no socket) and
  `test/manifest_wiring_test.dart` (routes <-> shells <-> seams).

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
