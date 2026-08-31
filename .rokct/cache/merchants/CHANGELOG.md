## 1.21.0

* Gates 1 and 2 of design strip section 45 — the two doors to `/calc`
  on the manager side (frames 45b and 45c; chips 842 and 843, with 840
  on the calculator's side). `calc_sdk` ships a live `/calc` route
  (composed at `paas_manager/composer.json:162`) that **nothing
  navigated to**; these are the ways in.
  * **842 — the Calculator row on the hub** (frame 45b): a second row
    in the PRODUCTIVITY group that frame 7e created for Tasks, with the
    same earn-your-glance sub-line idiom. Costs nothing structurally —
    one `SectionsItem` in a group that already exists, routing the way
    every other hub row routes (the host's generated `CalculatorRoute`
    via the already-imported `app_router`), and merchants_sdk never
    imports calc_sdk.
    * The approved render's glance ("Memory holds 1 240.50") is SEEDED
      behind `AppConstants.isDemo`, exactly as the Tasks counts are.
      Frame 45b names the fork itself — *"either the row drops the
      sub-line, or memory gets persisted"* — and live memory is not
      readable from here: `calculatorProvider` is an in-memory
      `autoDispose` `StateNotifier` inside calc_sdk, so the value does
      not survive the page, and reading it across SDKs would need a
      base_sdk `LocalStorage` key (a base_sdk change). Real composes
      show the plain row until then.
  * **843 — the till's calculator shortcut** (frame 45c): a THIRD chip
    inside the amount card's quick-chip row, after "Full amount" and
    "R0 all on credit" — deliberately not a header button and not a
    FAB, so it reads as one more way to fill the amount rather than a
    detour. Primary-tinted with the calculator glyph so it reads as an
    action rather than a preset.
    * It opens `/calc?pick=true` and takes the number back into the
      amount display (chip 840, calc_sdk 1.1.0). **Calc feeds the
      keypad; it does not replace it** — chip 390 stays exactly where
      it is and is not modified. The result never touches the cart, the
      order or a balance.
    * Navigation is BY ROUTE PATH, so merchants_sdk still never imports
      calc_sdk (ADR-005). A composition without calc_sdk, or on a
      calc_sdk older than 1.1.0, gets `null` back and the amount is
      untouched — the two PRs are order-independent.
  * `_quickAmountChip` gains an optional glyph and a primary tint; the
    two existing chips render byte-identically.
  * One new manager `tr_key`: `calculator`, declared with the same wire
    value calc_sdk declares, so a double declaration resolves to the
    same string either way.

## 1.20.1

* Dark-mode fix — the manager profile hub's lower two-thirds was
  unreadable. When the hub moved onto base_sdk's `GenericProfilePage`
  (PR #75) its scaffold became `AppStyle.surfaceDark` (#101010 in dark
  mode). The shop block at the head of the page was repointed to the
  mode-resolving ink tokens; the blocks below it were missed, so on a
  dark build:
    - every Sections / PRODUCTIVITY row title painted
      `AppStyle.blackColor` (#000000) — 1.10:1 against the page, i.e.
      invisible. Now `AppStyle.textPrimary` (`sections_item.dart`).
    - both group titles fell through to `TitleAndIcon`'s pinned
      `titleColor` default, `AppStyle.black` (#232B2F) — 1.32:1, also
      invisible. The two hub call sites now pass
      `titleColor: AppStyle.textPrimary` explicitly. The shared default
      in base_sdk is deliberately LEFT pinned: ~90 fleet call sites sit
      on `ModalWrap`'s white sheet (including the two sheets this hub
      opens), and flipping it would blank those instead.
    - the working-hours pill stroked `AppStyle.borderColor` (#E6E6E6) —
      the inverse failure: a near-white 15.25:1 hairline shouting off a
      page whose every other stroke is #2E2E2E, and 1.06:1 (invisible)
      on the light page. Now `AppStyle.strokeDark`, the token
      `GenericProfilePage` strokes its own cards with.
  No layout, copy or routing change; ink and stroke only.
* Test: `profile_hub_dark_mode_test.dart` — pumps `SectionsItem` and
  `TitleAndIcon` in both polarities and holds their resolved ink to the
  WCAG 1.4.3 4.5:1 body floor against the host surface, and gates
  `restaurant_page.dart` (a `${package}` template, unpumpable from this
  package and excluded from CI) on paint tokens that resolve with the
  mode. Fails on the pre-fix tree at 4 passed / 6 failed.


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
