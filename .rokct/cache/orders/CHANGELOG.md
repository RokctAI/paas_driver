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
