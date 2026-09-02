# Changelog

## 1.4.0

* `DemoKitchenOrdersRepository` — demo data behind the manager Kitchen tab.
  `ManagerKitchenDependencies.register` now selects it over
  `KitchenOrdersRepository` under `--dart-define=IS_DEMO=true`, the same
  `AppConstants.isDemo` split merchants_sdk's POS seams and products_sdk's
  catalog facades use. Nothing about the production path changed.
  * WHY: this SDK's tour fragment shipped in 1.3.0 but was not worth
    chaining into an app tour, because a demo build rendered the screen's
    "no orders" empty state.
  * WHAT IT SERVES: five fictional tickets across accepted / cooking /
    ready, with dish lines at mixed prep states, cook-visible notes on two
    of them, and creation times a few to thirty minutes back so the cards'
    flip clocks tick. Filter counts are computed off the live queue.
  * WRITES are acknowledged in memory: advancing a dish, starting a cook,
    marking ready or handing over sticks for the session and resets on the
    next launch. A hand-over status the kitchen vocabulary cannot express
    ('on_a_way' / 'delivered') drops the ticket out of the queue, exactly
    as a real refetch would. No HTTP client is ever constructed.
  * The seeded dishes deliberately match orders_sdk's demo order board.
    Duplicated rather than shared (ADR-005).
* Tour fragment: the demo-grounding note is rewritten; the step is now a
  live-queue capture rather than an empty state.

## 1.3.0

* The manager KITCHEN screen — the APPROVED design (Ray 2026-08-29:
  12:36Z "yes" to bringing the paas_pos kitchen's behaviour to the
  manager app; 13:06Z the kitchen-declares-ALL redesign + "approved: …
  34b,34c,34d"; 13:53Z "approved: 34a …"). kitchen_sdk was picker-only;
  this release adds its first screen, all machinery as analyzable,
  tested package code under `lib/src/manager/` with a thin installed tab
  page (orders_sdk 1.11.0's architecture):
  * QUEUE (`KitchenQueueView`): the POS filter chips
    All / Accepted / Cooking / Ready / Cancelled with live counts; order
    cards with the POS's order-type glyphs (bike/walk/dine), the placed
    time, the status pill, the dish-preview line the ALL declaration's
    extra width buys, and "View more · +N" paging; debounced
    order-number search behind a header toggle; the new-order chime
    (engine `SystemSound`, orders_sdk's no-audio-package call) with the
    bell activity dot; auto-refresh polling on base_sdk's shared
    30-second cadence.
  * FLIP CLOCK (`KitchenFlipClock` + pure `KitchenClock`): split-flap
    tiles, hours tile only when > 0; amber digits at 30 minutes, red +
    "Delayed" tag at the hour (the approved delta: the POS swapped the
    clock for the word — the red clock stays visible here); frozen and
    dimmed at Ready/Cancelled at the order's actual span. Ticks from the
    order's CREATION (the POS ticked from its cooking-start timestamp;
    this backend's `modified` moves on every save, so creation is the
    honest baseline) — deviation documented in the widget.
  * DETAIL (`KitchenDetailPane`): dish-by-dish prep pills — TAP advances
    Pending → Preparing → Done, DOUBLE-TAP cancels the line (approved
    34d labels; POS order_details_item.dart), with the affordance hint
    as real microcopy; the cook-visible customer note card; the one-tap
    flow — accepted → "Start cooking" (marks every live line preparing),
    cooking → "Mark order ready" (guarded on >= 1 done dish), ready →
    "Hand over" (the POS's post-Ready routing: pickup/dine-in →
    delivered, delivery → on the way) — and the confirm-guarded
    "Cancel order…".
  * AUTO-RULES (`KitchenRules`, pure and unit-tested): all dishes
    cancelled auto-cancels the order; all dishes done while cooking
    auto-flips it Ready; the ready guard — the POS KitchenNotifier's
    state machine verbatim.
  * PLANES (`KitchenPlaneFlow`): the kitchen declares `PlaneSpan.all`
    (base_sdk 1.43.0) — at three planes the queue spreads over planes
    1–2 (four cards a row) with the selected order's detail in the LAST
    plane, auto-select keeping it filled (no bare stage, approved 34a);
    at two planes queue | detail; phones collapse to queue → pushed
    detail with the corner back pill by construction (34b/34c, the
    12:36Z nav fold). On multi-plane widths the detail is a permanent
    pane — full centered shell nav, no fold, exactly frame 34a.
  * DATA: kitchen's own frappe module grows the queue + dish-status
    endpoints (`api.cook.get_kitchen_orders`,
    `api.cook.update_kitchen_dish_status`) over the new Order Item
    `prep_status` field; order-level transitions ride the EXISTING
    `api.seller_order.update_seller_order_status`. All calls go through
    the universal platform gateway (this SDK's KitchensRepository
    precedent).
  * Manifest: first `app_type.manager` block — the tab page install
    (merchants_sdk >= 1.14.0 mounts it), the `di_hooks` registration,
    and 11 new tr_keys (Afrikaans fallbacks bundled).

## 1.2.0 and earlier

* Picker-only SDK: kitchen (prep station) domain models, repository, and
  the manager product-form picker providers (commerce PR #18); bundled
  Afrikaans translations boot hook.
