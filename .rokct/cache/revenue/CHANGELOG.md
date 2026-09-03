## 1.12.0

Design strip frames 49f (chip 973) and 49i, manager side — the bank-deposit
route reaches revenue_sdk. The driver's screens for it (49g/49h/49i) live
in delivery_sdk >= 1.18.0; the backend in RokctAI/pay's wallet module.

* **Top up on the driver's wallet plane (chip 973).** `DriverWalletPage`
  now draws Top up under Withdraw. It pushes delivery_sdk's
  `/driver-deposits?choose=1` — the deposit status plane with the method
  chooser opened over it — by PATH, because revenue imports only base
  (ADR-005). A composition without the route hears one friendly line
  instead of seeing nothing, which is why the pill could ship at all: the
  page's doc comment used to list the two build-state facts that kept it
  out (no card surface composed, no deposit doctype), and the second is
  now false.
* **The deposit approval queue (frame 49i, manager side).** New, exported
  from the barrel: `DepositApprovalsPage` (plane 2 of the manager hub —
  each Pending request with the driver's name, amount, reference, when it
  was sent, the wallet it was sent against stated as a sentence, the slip
  in a viewer, and Approve / Reject; chip 347's back pill),
  `DepositRejectSheet` (a reason is required — the driver reads it under
  his row), `depositApprovalsProvider` with `DepositApprovalsNotifier` /
  `DepositApprovalsState` (drops a row the server accepted, one decision
  in flight at a time, friendly-line errors),
  `DepositApprovalRepositoryFacade` / `DepositApprovalRepository`
  (`api.wallet.list_pending_deposit_requests / approve_deposit_request /
  reject_deposit_request` over the platform gateway) and the typed
  `DepositRequestRecord` / `DepositResolution`. `ManagerWalletPane` gains
  a "Deposits to approve" entry under the debit notice
  (`showDepositApprovals`, default true) — a row, not a second action on
  the card's strip. The facade is registered by the manager role hook
  only: approve/reject are role-gated server-side and no driver surface
  draws the queue.
* Guarded by `test/deposit_approvals_test.dart` and
  `test/deposit_approval_repository_gateway_test.dart`; the 49l pane
  test still passes with the new row. Manifest 1.11.1 -> 1.12.0.

## 1.11.1

* **Frame 49l, the commerce seam declared (no code change).** Two
  `integrations` entries target the manager hub
  (`lib/presentation/pages/manager/restaurant/restaurant_page.dart`, the
  installed copy of merchants_sdk >= 1.25.0's restaurant page):
  `// @revenue-manager-wallet-imports` (column 0) receives
  `import 'package:revenue_sdk/revenue_sdk.dart';` and
  `// @revenue-manager-wallet` (six-space indent, first in
  `MerchantWalletSection`'s candidate list, which renders `.first`) receives
  `ManagerWalletPane(scope: ManagerWalletScope(shopId:
  merchantWalletScope(ref).shopId, shopName: merchantWalletScope(ref).shopName))`,
  so the pane wins over base's bare `BaseWalletCard` without deleting it.
  The placeholder keeps its indent because the bare text is a prefix of the
  imports marker and the installer replaces every occurrence. On an older
  merchants_sdk the installer warns "marker not found" and the hub is
  unchanged. `test/manager_wallet_integration_test.dart` pins the strings
  (byte-for-byte twin of merchants' `test/hub_markers_test.dart`) and that
  every symbol the replacement names outside the host is on the barrel.
  Manifest 1.11.0 -> 1.11.1; pubspec on its own rail.

## 1.11.0

* **Design strip frame 49l — the manager withdraws (revenue half).** Ray
  approved 49l on 2026-08-31 ("49d, 49f-l approved"). The frame puts ONE
  action on the manager hub's `BaseWalletCard` strip (chip 989) beside the
  same debit-at-request notice the driver's sheet carries (chip 986); the
  request sheet, no-account sheet, sent sheet and payout trail are
  49j/49n/49r/49k reused, because the endpoint, doctype, debit timing and
  credit-back are identical for both actors. New, exported from the
  barrel: `ManagerWalletPane` (the card with the action, the history arrow
  into the trail and the notice), `ManagerWithdrawAction` (the action on
  its own, for a host that keeps its own card), `managerWalletProvider`
  keyed by `ManagerWalletScope(shopId, shopName)`, with
  `ManagerWalletNotifier` / `ManagerWalletState`. The commerce half — the
  merchants restaurant page passing the pane where it passes
  `actions: []` today — is a separate PR and needs no further revenue
  change.
* **The shared payout surface moved from `src/driver/` to `src/common/`**
  so a manager cache (whose `src/driver/` the composer strips) can reach
  it: `DriverPayoutRepository`, the withdraw / bank / payouts application
  slices, `WithdrawSheet`, the bank-details pages and sheets (49n-49s),
  the payout trail page and widgets (49k), and `wallet_grammar.dart` (pure
  arithmetic and wording the trail shares with the wallet plane). Files are
  moved, not rewritten; only import paths changed. The driver wallet plane
  (49f), `DriverWalletRepository`, courier statistics and the driver DI
  stay in `src/driver/`. No re-export shims at the old paths: nothing
  outside this SDK imported them (fleet clones and the driver host grep to
  zero); the driver income template and this SDK's tests now import the
  new paths.
* `ManagerRevenueDependencies.register` now also registers
  `DriverPayoutRepositoryFacade` -> `DriverPayoutRepository` (guarded, so
  a host that runs both role hooks double-boots safely). The seam keeps
  the driver's name: wallet's `api.payout.*` is USER-scoped and serves any
  signed-in user, and renaming it would churn the driver's shipped code
  for no behaviour change — follow-up, not this PR.
* `ManagerWalletScope` is NOT sent on the wire. `request_payout` reads
  the session user (`payout.py:350`) and debits that user's wallet; the
  merchants page already treats the profile wallet as the seller balance.
  Whether a shop withdraws to the shop's own account or to the manager's
  personal one is the question frame 49l flagged for Ray; the scope sits
  at the seam so the host does not change when he rules.
* New `test/manager_wallet_pane_test.dart`: the pane renders the card,
  the action and the notice; an empty or negative balance leaves the
  action inert; a tap reads the bank accounts BEFORE anything opens, meets
  frame 49n's explanation with none on file and sends nothing; with an
  account on file the fleet-keypad sheet opens and the request delegates
  the typed amount and the named account to the repository, the sent
  sheet states the subtraction and the card draws the post-hold balance.
  `role_di_hooks_test` pins the manager hook's payout registration.
* Known compose-order collision, NOT resolved here (core, not this repo):
  `core/base/frappe/manifest.json:12` maps the same
  `{app_name}.api.payout.request_payout` key to a nonexistent
  `merchants.tenant.api.payout.payout.request_payout`, while
  `pay/wallet/frappe/manifest.json:42` maps it to the real
  `wallet.tenant.api.payout.request_payout`. Which one wins depends on
  compose order. Follow-up in core.

## 1.10.4

* **The manager revenue dashboard renders again.** Every scrolling column
  that carried the paired KPI tiles collapsed to nothing. The guided tour
  photographed it on both legs of `paas_manager` run 33623501812 (commit
  `3543a6b6`): the phone's `16-revenue_income` came back one flat empty
  fill — no header, no period selector, no chart, no product rows, not even
  a zero state — and the tablet's kept its profit-by-product list on the
  right while the whole left column, where the revenue-vs-profit chart
  belongs, went blank.
* **The cause was the pairing row, not the chart.**
  `_kpiTiles(paired: true)` put profit|margin and orders|avg into a
  `Row(crossAxisAlignment: CrossAxisAlignment.stretch)`, and all three
  callers drop those rows straight into a `ListView`. A stretch row hands
  its children its own incoming maxHeight as a TIGHT height, and a
  ListView's incoming maxHeight is infinite — so each tile was asked to be
  infinitely tall and layout threw `BoxConstraints forces an infinite
  height` (`revenue_workspace.dart:530`, `BoxConstraints(0.0<=w<=Infinity,
  h=Infinity)`). Flutter catches that at the row's own `layout()`, which
  then has no size, and the failure walks up through `SliverList` to the
  viewport. A viewport is `sizedByParent`, so it keeps its own size while
  its sliver has no geometry: the column renders nothing while everything
  beside it renders fine — exactly the two frames above. The 45 repeats of
  `'!semantics.parentDataDirty': is not true` that then failed the run's
  `flutter test` are downstream of the same abandoned layout — they begin
  after the revenue screen, and every rendering error in both legs' logs is
  raised by `revenue_workspace.dart`.
* **The fix**: `_pair()` wraps each pairing row in `IntrinsicHeight`, which
  measures the taller tile first and gives the row a FINITE height to
  stretch against. The approved equal-height pairing is preserved — that is
  what `stretch` was there for — it simply has something real to match now.
  Two tiles per row, so the intrinsic pass is negligible.
* `test/revenue_workspace_layout_test.dart` is the guard, and it asserts
  GEOMETRY rather than the widget tree: a `ListView` builds lazily during
  layout, so when layout is abandoned the children after the failure are
  never built at all and a "the chart exists" check would have passed on a
  blank screen. It pumps the real `RevenueWorkspace` at one-, two- and
  three-plane widths and requires the trend chart and every KPI tile to
  come back with a finite, positive size, no `forces an infinite height`
  and no `was not laid out`, and the paired tiles to agree on height. All
  four cases fail on 1.10.3.
* Nothing else changed: no interface, no repository, no state, no chart
  code. `RevenueTrendChart` was never at fault — it is a `CustomPainter`
  with no charting dependency (the `charts_flutter` 1.10.3 declares is the
  DRIVER income template's, a different page), and it was simply downstream
  of the row that broke its column.

## 1.10.3

* **The driver income page's chart dependency now travels with the SDK.**
  `templates/pages/driver/income/income_page.dart` imports
  `charts_flutter` to build the earnings `Series` in the host package, but
  neither this pubspec nor the generated host pubspec
  (`core/base/dart/templates/pubspec.yaml`) declared it — the manifest
  comment said it "stays in the host pubspec", and only the pre-fork
  `paas_driver` happened to pin it by hand. Every other composed driver
  host failed to resolve the import. `charts_flutter` is now a dependency
  of `revenue_sdk` (the same discontinued-upstream git fork `paas_driver`
  pinned), so it reaches every composed host transitively.
* The fork pins `intl ^0.20.2` while `base_sdk` and this SDK declare
  `^0.19.0`; a `dependency_overrides` entry mirrors the host template's
  own `intl: ^0.20.2` arbitration so standalone resolution matches what
  every composed build already uses. The manifest `_comment_app_type`
  no longer claims the host owns the pin.
* New `test/driver_income_template_deps_test.dart`: `templates/` is
  excluded from analysis and compiles only after install, so the guard is
  structural — every `package:` a template imports must be declared in
  this pubspec, be the SDK or Flutter itself, or be a named composition
  peer (`merchants_sdk`, `products_sdk`, resolved by the manager income
  page in a composed manager host).
* Medium-term follow-up (not this change): port the chart to `fl_chart`
  and drop the discontinued `charts_flutter` fork.

## 1.10.2

* **The composed manager build compiles again.** 1.10.0 grew
  `SellerStatisticsRepositoryFacade.getProfitReport` for the section-36
  profit dashboard and added it to `SellerStatisticsRepository`, but not to
  `DemoSellerStatisticsRepository`. A demo class is only ever reached
  through the facade at runtime, so nothing surfaced it until the composed
  `paas_manager` guided tour died at "Build Demo Debug APK":
  `The non-abstract class 'DemoSellerStatisticsRepository' is missing
  implementations for these members: -
  SellerStatisticsRepositoryFacade.getProfitReport` → `Target
  kernel_snapshot_program failed`. The build failing meant the manager tour
  never ran a single test.
* **The fix is additive**: `DemoSellerStatisticsRepository.getProfitReport`,
  the exact interface signature (`{required DateTime from, required DateTime
  to}` → `Future<ApiResult<ProfitReportResponse>>`), answering from the same
  fictional store week the demo's `getStatistics` already serves. The
  interface is untouched — no optional member, no default implementation —
  and `SellerStatisticsRepository` is untouched. `getStatistics` and
  `getStatisticsOrder` keep their previous answers byte for byte.
* The demo report is honest rather than flattering: one product row carries
  no cost snapshot, so the "cost not set" state and the unknown bucket both
  render, and excluded revenue is never counted as pure profit. Per-day
  figures key off the calendar date rather than position in the window, so
  the dashboard's second call — the shifted previous window — comes back
  with different numbers and the vs-previous-period delta pills actually
  appear. A single-day window answers per hour, matching what the endpoint
  does when `from == to`.
* `test/demo_seller_statistics_test.dart` is the structural guard: it binds
  `DemoSellerStatisticsRepository` to a variable typed as the FACADE, so the
  SDK's own test run stops compiling the moment a member is added to the
  interface and not to the demo — before a composed app ever builds. It
  also pins the coherence rules above.
* Every other implementer of the facade was checked: `SellerStatisticsRepository`
  (real, complete) is the only other one, and both implementers of the
  sibling `CourierStatisticsRepositoryFacade` were already whole.
* No interface change, no change to any real repository, no rendered pixel
  change outside demo builds.

## 1.10.0

* **The manager income page can now resolve its repository.** Composed
  `paas_manager` builds crashed on first paint of `/income` with
  `Bad state: GetIt: Object/factory with type
  SellerStatisticsRepositoryFacade is not registered inside GetIt`
  (`income_page.dart` → `statisticsProvider`). The registration was never
  missing: `ManagerRevenueDependencies.register`
  (`lib/src/manager/di/manager_revenue_di.dart`) registers the facade
  correctly, under both sides of the `AppConstants.isDemo` split. It was
  never **called**. `app_type.manager` had no `di_hooks` entry, so the
  installer injected nothing into the composed app's generated `main.dart`,
  and no host wired it by hand either — the class compiled perfectly while
  nothing on earth invoked it.
* **The fix is one manifest entry**: `revenue-manager-role-di`, order 14,
  body `ManagerRevenueDependencies.register(GetIt.instance);`, shipping the
  direct `src/manager/di/manager_revenue_di.dart` import the barrel
  deliberately does not export. It mirrors this SDK's own
  `revenue-driver-role-di` and `merchants_sdk`'s
  `merchants-manager-role-di`. Order 14 rather than 12 because
  `kitchen_sdk` and `merchants_sdk` already both sit at 12 in the manager
  flavour; the injector keeps every colliding hook but warns per shared
  order, and these registrations are independent of each other.
* **This is the third app to be bitten by the same shape** — `paas_driver`
  died the same way on `CourierStatisticsRepositoryFacade` (delivery_sdk's
  driver hook, zones#85) — so the guard added here is structural rather
  than role-specific. `test/role_di_hooks_test.dart` walks
  `lib/src/<role>/di/` and fails if any class it finds there is not named
  by a `di_hooks` body under its own role, with the matching direct `src/`
  import. Add a new role DI file without the manifest entry and the test
  fails before a composed app ever boots. It also pins that `register()`
  really does put `SellerStatisticsRepositoryFacade` (and the three driver
  facades) into GetIt, and that calling it twice is harmless.
* Class docs on `ManagerRevenueDependencies` and `RevenueSdkDependencies`
  corrected: they described the manager hook as something "a manager host
  calls from its own DI setup", which was the plan and never the practice.
  They now name the manifest hook that actually calls it.
* No behaviour change for the driver role, no interface change, no rendered
  pixel change.

## 1.9.2

* **Correction to the record on `DriverWalletPage`: frame 49g IS approved.**
  The class doc, and the 1.8.0 note below it, both said 49g "is not
  approved" and used that as the first reason the Top up action (chip 973)
  was left off the wallet plane. That was wrong — section 49's own header
  records every frame 49a–49s as approved. The 1.8.0 entry is left as the
  historical record it is; the class doc is corrected in place, because it
  is what the next person to open the file will read.
* **The omission itself is unchanged, and its real reasons are now written
  down** — both re-verified against `origin/main` on 2026-08-31:
  * *The card branch has nowhere to go.* `wallet_sdk` ships the surface
    (`/wallet-topup`; `process_wallet_top_up` behind it is finished), but
    **no composed app installs `wallet_sdk`** — not `paas_driver`, not
    `paas_manager`. The SDK registry lists `supacharge` as its only
    consumer. The route a Top up pill would open does not exist in the
    driver app, and composing an SDK into a shipping app for the first time
    is a composition change, not an entry on this page.
  * *The bank branch has nowhere to land.* 49h/49i need a deposit doctype
    and `pay/wallet/frappe/src/tenant/doctype/` still has none —
    flutterwave_settings, payment_payload, payout_bank_account,
    platform_wallet, saved_card, transaction, wallet, wallet_history,
    wallet_payout_request, wallet_receive_claim, and nothing deposit-shaped.
* No behaviour, no interface and no rendered pixel changes in this release:
  it is a comment and a version.

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
