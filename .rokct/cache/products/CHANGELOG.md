# Changelog

## 1.7.0

* `DemoSellerProductsRepository` + `DemoSellerCatalogRepository` — demo data
  behind the manager's foods tab. `ProductsSdkDependencies.register` now
  selects them over `SellerProductsRepository` / `SellerCatalogRepository`
  under `--dart-define=IS_DEMO=true`, the same `AppConstants.isDemo` ternary
  this SDK already applies to its customer-facing products, categories and
  brands facades. Nothing about the production path changed.
  * WHY: the guided tour runs the app in demo with zero backend calls, so
    the `menu` still was capturing three empty tabs.
  * WHAT THEY SERVE: six sellable dishes over three categories (Mains,
    Sides, Drinks), two add-ons, two extras groups (Heat, Portion), three
    units, and a sub-shop category pair — enough for the catalog strip, the
    add-ons tab, the extras tab and the create-product form's pickers to
    render stocked without spilling past one screen.
  * WRITES are acknowledged in memory: creating, editing, re-stocking or
    deleting during a tour sticks for the session and resets on the next
    launch. No HTTP client is ever constructed and nothing leaves the
    device.
  * The seeded dishes deliberately match orders_sdk's demo order board.
    Duplicated rather than shared (ADR-005).
* Tour fragment: the demo-grounding note and the `menu` caption no longer
  frame the screen as a brand-new shop's empty menu.

## 1.6.0

* The APPROVED product management + stock update surfaces (Ray 2026-08-29
  15:41Z "approved: 7e, 11u,35a,35b,35c,35d,35e." — coverage groups F + G,
  frames 35a–35e), replacing the light foods page + edit modal presentation
  with the settled plane-model workspace. Machinery is analyzable, tested
  package code under `lib/src/manager/` (orders_sdk 1.11.0 / kitchen_sdk
  1.3.0's architecture); the installed templates are thin glue plus the
  shipped form bodies re-dressed.
  * CATALOG (35a/35c): FoodsPage becomes a workspace whose catalog
    declares ALL planes (`CatalogPlaneFlow`, the kitchen's 13:06Z
    "takes all until another come" precedent) — grid over planes 1–2
    (span + 1 columns), search + category chips (the approved 11m
    language) + the Foods/Add-ons/Extras inner tabs with counts in the
    header, and the selected product's READ-ONLY detail in the last
    plane (`ProductDetailPane`) with wide-screen auto-select. Phones
    keep the one-plane list and the shipped tap-straight-to-edit — the
    tablet-only read stop is the approved deliberate asymmetry.
  * STOCK-STATE GRAMMAR (35a/35f, the parked paas_pos 32a idea landed):
    amber "Low · N left" badge + amber count BELOW 10, red badge +
    price-replacement AT 0, silence when healthy — thresholds are the
    named constant `kLowStockThreshold` (`StockGrammar`, unit-tested);
    card tint and pulsing icon deliberately NOT carried (badge + count
    color is the dark-language redraw).
  * PROFITABILITY STRIP (35a, the 14:51Z groundwork): Price · Cost ·
    Margin on the read detail, CLIENT-SIDE from the existing price +
    manager-only cost fields (`ProductMargin`, unit-tested; "cost not
    set" when cost is missing/zero, negative margins shown red). The
    revenue-aggregates endpoint stays group I's later work.
  * EDIT (35b/35d): tapping Edit pushes `ProductEditPage` as a REAL
    route over the whole shell (the 12:36Z nav fold; kitchen_detail_page
    precedent) — the form declares TWO planes and the shipped modal's
    Details|Stocks tabs unfold into side-by-side panes
    (`ProductEditPlaneFlow` + `ProductFormSplit`), the origin catalog
    keeping plane 1 as the compressed `CatalogEditRail` (12:26Z origin
    rule); one plane folds back to the segmented tabs. The shipped
    bodies keep their notifiers, validators, request shaping and
    satellite picker sheets UNCHANGED — presentation only moved to the
    dark language (units|kitchen, interval|min|max, tax|cost-with-helper
    row groupings; variant cards labelled by their extras combination;
    "+ Add variant" surfacing the notifier's existing `addEmptyStock`).
    EditProductModal stays in the tree but is no longer opened.
  * QUICK STOCK UPDATE (35e): the approved standalone counts-only
    surface group G never had — `QuickStockView` + `QuickStockNotifier`:
    a stepper per stock row, Low-stock/Out triage chips (triage judged
    on the LOADED quantity so a row stays put while being corrected),
    "Save N changes" batch save riding the EXISTING `updateStocks`
    endpoint per changed product (full rows resent with only quantities
    swapped — no new backend). Bottom sheet on phones; a pushed plane
    pane at plane widths (the 12:02Z sheet fork) with the corner pill.
  * The ~10 CRUD satellite modals (categories/units/kitchens/extras/
    addons) stay the sheets they were — reachable from the new surfaces,
    untouched (the decision-transfer rule: sheets overlay, never take
    planes). The create flow (CreateProductModal + FAB-dispatch
    siblings) keeps its shipped sheet shape, now opened from the
    header's "+ New product" (no FAB in the floating-nav language —
    merchants_sdk 1.14.1 retires the shell FAB on the foods tab).
  * Requires base_sdk >= 1.43.0; new manager tr_keys for the new
    surface language (see manifest).

* Tour fragment kept in step (the tour-sync rule): the add-product step's
  prose now points at FoodsPage's own "+ New product" header button — the
  same `Remix.add_line` tap target, so the step's dart is unchanged — and
  the header notes the shell FAB no longer covers the foods tab
  (merchants_sdk 1.14.1).

## 1.5.1

* Tour fragment: the foods step selects home-shell tab index 3
  (merchants_sdk 1.14.0 mounts the Kitchen tab at 2, shifting foods
  right; the fragment had already gone stale at index 1 when the
  POS-first shift moved foods to 2 — it was landing the tour on the
  order queue). No code changes.

## 1.5.0 and earlier

* See the repository history — this changelog starts at 1.5.1.
