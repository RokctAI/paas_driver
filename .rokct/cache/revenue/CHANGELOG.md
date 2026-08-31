## 1.8.0

* The driver's own money surface, drawn from the approved design strip
  frames **49f (the wallet plane)** and **49k (the payout trail)**. Until
  now the driver app had no wallet screen at all: a read-only number on the
  profile page, a second read-only number on the income page, and (before
  1.7.0) a Withdraw button wired to `onPressed: () {}`. He could see a
  figure he could not explain.

  * **`DriverWalletPage`** (`src/driver/presentation/wallet/`) — frame
    49f, plane 2, pushed on the root navigator so the host's nav folds to
    the canonical corner back pill (chip 347) and no floating nav is
    drawn. It carries the balance head, the withdraw action and the
    statement.
  * **`DriverBalanceHead`** (chip 971) — the balance as a SENTENCE, never
    a signed number: "You owe R 1,240.00", not "−1,240" (section 49 ruling
    11). A negative balance is DELIBERATE and normal — the driver keeps
    the physical cash he collects and his ledger carries the debt
    (`commerce/orders/.../settlement.py:48-52`,
    `zones/delivery/.../driver_parcel.py:172-175`,
    `zones/map/.../driver_order.py:745-748` all say so) — so it is stated
    with the reason under it, never flagged as an error. It also carries
    the month's gross delivery fees, read from the courier order report
    this SDK already owns.
    *This is NOT base_sdk's `BaseWalletCard`, and that card is untouched:*
    the shared card renders the balance as a signed number inline and
    hides it entirely at zero, which is the opposite of both requirements
    above. Bending it would have changed behaviour the manager app renders
    today.
  * **`WalletMovementList`** (chip 972) — the statement, from
    `api.user.get_wallet_history`. A cash debit and the fee credit that
    share ONE settlement stay two rows, because that is what the ledger
    contains. Direction is derived from the SIGN first and the
    transaction type second: the ledger has two writers that disagree
    about the sign (wallet stores `abs()` and puts the direction in the
    type; commerce's settlement stores a signed amount), and a sign-only
    or type-only rule draws half the rows backwards. Folds to six rows and
    unfolds in place — no "all movements" screen has been approved.
  * **`DriverPayoutsPage`** + **`PayoutStatusTrail`** (chip 987) +
    **`PayoutHistoryList`** (chip 988) (`src/driver/presentation/
    payouts/`) — frame 49k, plane 2 of income. It exists because a balance
    that has already dropped, against a payment that has not yet arrived,
    is the exact gap in which a driver decides the app has stolen from
    him. The trail FORKS: `Requested` is the only live node and `Paid` /
    `Rejected` hang off it as alternatives, because that is what the
    doctype's Select models (`wallet_payout_request.py:52`) — a line would
    promise that every request eventually pays. A rejected or cancelled
    row states the fact that matters more than the reason: the money went
    back, through `_release_hold` (`:118-150`), latched by `hold_released`
    so it happens at most once.
  * **`DriverWalletRepository`** + **`DriverWalletRepositoryFacade`** +
    **`WalletMovement`**, and **`listPayoutRequests`** added to the
    existing payout seam with **`PayoutRequestRecord`**. Three reads —
    `api.payment.get_wallet_balance`, `api.user.get_wallet_history`,
    `api.payout.list_payout_requests` — all by prefix-free dotted name
    through base_sdk's universal platform gateway, whose path is already
    the versioned `/api/v1/method/...` form. paas_driver composes neither
    `wallet_sdk` nor a users SDK, so nothing is imported from either: the
    same cross-app pattern `CourierStatisticsRepository` already uses.
    Registered by `DriverRevenueDependencies`. The two answers differ in
    shape on purpose — the statement arrives in the shared
    `api_response` `{"data": [...]}` envelope, the payout list arrives
    bare — so each model owns its own unwrapping and both are tested.
  * **`WalletBalanceCache`** — the one place a freshly-known balance is
    written back onto the cached profile, so the wallet plane, the income
    page, the profile readout and the withdraw sheet cannot disagree about
    how much money there is. `WithdrawNotifier` now mirrors through it
    instead of holding its own copy of the same twelve lines; behaviour is
    unchanged.
  * The withdraw action on the wallet plane opens the SAME `WithdrawSheet`
    and the SAME `withdrawProvider` as the income page — chip 983 is one
    element on two screens, not two withdraw implementations that can
    drift apart. It is live only on a strictly positive balance, and the
    line under the inert control is frame 49f's own wording.
  * Error wording unchanged from 1.7.0 and applied to every new read: only
    a friendly named line reaches the driver — never the raw server
    message, never a distinction between one backend cause and another —
    while the verbatim detail and status code ride base_sdk's
    `ErrorPresenter.showTechnical` telemetry door. `ErrorPresenter.show`
    is deliberately NOT used: Frappe answers a `frappe.throw` with 417,
    inside the band `show` would echo verbatim.
  * Templates carry thin wiring only (`templates/pages/driver/income/
    income_page.dart`): the wallet row opens the plane and a "Your
    payouts" link opens the trail. All substance is in analyzable `lib/`.

  **Drawn on the frames but deliberately NOT shipped, each flagged rather
  than forgotten:**

  * **Top up (chip 973).** Frame 49f draws it as the entry to 49g, which is
    not approved: its card half has no card-entry surface in this app and
    its bank-deposit half (49h) needs a doctype that exists nowhere in the
    fleet. A pill that opens nothing is the exact dead control this plane
    was drawn to end.
  * **The cash-on-hand figure** ("You're holding R 470.00 in cash"). No
    endpoint on the driver path exposes it — frame 49f flags this itself.
    The line that does not need it ("cash is docked the moment you mark
    Delivered") is kept, because it is true and it is what explains the
    negative number.
  * **The rejection reason** on a payout row. `Wallet Payout Request`
    stores none, so none is drawn.
  * **The per-row sentence** on the statement.
    `get_wallet_history` does not select the `description` column that
    every writer fills in, so rows fall back to a deliberately coarse
    type label. The model parses `description` anyway: adding that one
    column to the def's field list makes these rows read exactly as frame
    49f draws them, with no client change.
  * **Cancelling a live payout.** The endpoint exists
    (`payout.py:388-427`) and frame 49k deliberately draws no affordance
    for it: who may cancel, and until when, is unsettled policy.

## 1.7.0

* The driver income page's **Withdraw Money** button now works. It shipped
  as `onPressed: () {}` — a dead control on a money screen — and now opens
  a real withdraw step and sends a payout request to the backend.

  * `WithdrawSheet` (`src/driver/presentation/widgets/`): the same dark
    bottom sheet as delivery_sdk's `CashCollectionSheet` — drag handle,
    available-balance card, a NON-FOCUSABLE amount read-out so the OS
    keyboard can never appear behind the pad, then base_sdk's
    `MoneyKeypad`. Ray's standing rule is that the keypad is the
    money-entry surface wherever amounts are typed; no new chrome was
    invented for this screen.
  * `DriverPayoutRepository` + `DriverPayoutRepositoryFacade` +
    `PayoutRequestResponse`: wallet's whitelisted
    `api.payout.request_payout` def, reached by prefix-free dotted name
    through base_sdk's universal platform gateway. paas_driver composes no
    `wallet_sdk`, so nothing is imported from it — the same cross-app
    pattern `CourierStatisticsRepository` already uses for delivery's and
    map's defs. Registered by `DriverRevenueDependencies`.
  * `WithdrawNotifier` / `withdrawProvider` (`src/driver/application/
    withdraw/`): plain immutable state, matching the statistics slice.
  * Client-side guards, so a driver is never sent on a round trip he
    cannot win: no amount above the balance the page is already showing,
    no zero or negative, and a wallet at or below zero cannot request at
    all — the button is inert with a plain line under it. A driver's
    balance going NEGATIVE is deliberate and normal (he keeps the cash he
    collects and his ledger carries the debt), so that state is stated
    plainly rather than dressed up as an error. The server stays the
    authority: it re-reads the balance under a Wallet row lock.
  * Error wording follows the standing rule: only a friendly line reaches
    the driver — never the raw server message, and never a distinction
    between one backend cause and another — while the verbatim detail and
    status code ride base_sdk's `ErrorPresenter.showTechnical` telemetry
    door. `ErrorPresenter.show` is deliberately not used here: Frappe
    answers a `frappe.throw` with 417, inside the band `show` would echo
    verbatim.
  * The wallet is debited AT REQUEST TIME (wallet `payout.py` takes the
    hold when the request is created, not at approval), so on success the
    notifier writes the server's new balance onto the cached profile and
    the page rebuilds off it — the readout drops immediately, which is
    what the server actually did.

## 1.6.0

* Manager income page REWRITTEN as the approved revenue/statistics
  dashboard with profitability (design section 36, chips 654–674 — Ray's
  2026-08-29 14:51Z requirement, approved 2026-08-30 10:38Z: 36a tablet
  workspace / 36b phone / 36c drill-down). The old manager income
  templates (app_bar_screen, chart, order_prices_section,
  statistics_section, statistics_item) predated the common wrap and did
  not compile; they are replaced by ONE template shell — all machinery
  now lives in analyzable, tested package code (`src/manager`):

  * `RevenueWorkspace` + `RevenuePlaneFlow`: the dashboard declares ALL
    planes (KPI column | revenue-vs-profit chart + status split |
    profit-by-product), the product drill-down pushes into the LAST
    plane and the origin compresses to the 36c mini-KPI rail; phones get
    the 36b single column with a REAL pushed detail route. The pushed
    detail folds the nav to the corner back pill (12:36Z); at top level
    the template shows the FULL centered floating nav with the Profile
    tab lit (the locked "workspace, not pushed page" decision) — a tab
    tap selects on mainProvider and pops to the shell.
  * Profit, as sold: `get_seller_profit_report` (merchants >= 1.15.0)
    consumed via the existing `api.seller_report` cmd path — Profit and
    Margin%-of-costed-revenue KPI tiles, profit line on the trend chart
    (drawn by a CustomPainter, no chart dependency), per-product
    profitability in the canonical 35a Price/Cost/Margin grammar with
    the "cost not set" state, and the amber unknown-cost bucket banner —
    cost_price <= 0 lines are excluded and NEVER counted as pure profit.
    Until that backend is deployed the dashboard degrades honestly: the
    payout strip and today-count still ride the shipped
    `get_order_report`, and the profit content shows a named error card
    with retry — no fake zeros (PRs mergeable in any order).
  * Ray's paas_pos grammar preserved: Today/Week/Month segments + custom
    date-range chip, vs-previous-period delta pills (computed by calling
    the endpoint for the shifted window), the Avg order card; his old
    revenue−expenses "Profit" card is superseded by the cost-based math
    he asked for. The shipped page's data preserved: payout strip
    (restaurantRevenue/fmRevenue made honest as gross → platform fee →
    payout), status split, "More about orders" → order history.
  * Drill-down (36c): full-size margin strip, window Sold/Revenue/Profit,
    per-variant margin rows (variant price against the product-level
    cost — the shipped schema has no per-variant cost; per-variant sold
    counts and the 7-day margin sparkline need per-product series and
    stay v2), the cost-frozen-at-sale note, and "Edit cost price"
    jumping into the 35b product edit form (`ProductEditPage.open`, the
    locked decision — no new form). The template resolves the product
    through the working seller products list call searched by title (the
    details endpoint's legacy param naming answers empty).
  * Manager tr_keys replaced with the section-36 vocabulary; the driver
    income templates and the legacy statistics slice
    (`src/manager/application/statistics`) are untouched
    (backward-compat rule). New dependency: `remixicon ^1.2.0`.
  * Tests: profit report parsing + honesty rules, window/delta math, and
    the 36a/36c plane claims (`test/`).

## 1.5.0

* Floating-nav back conversion (approved design strip section 12, "no
  double back buttons" — base_sdk 1.39.0 / core#125): the driver and
  manager income template pages replace their standalone `PopButton`
  with the shared `FloatingBottomNav` carrying only the leading back
  segment — one back per screen. The driver page's withdraw button
  rides in the same bottom overlay, above the pill. Back-only (empty
  tab list): the driver app composes no root tab set, and the manager
  template's pushed route cannot reach its host app's root tabs from
  this SDK.
