## 1.3.1

* Route drawing sends ORS start/end as `lon,lat` strings instead of Dart
  record text, so directions requests no longer return HTTP 400 (code
  2003). `DrawRepository.getRouting` passed the records
  `(start.longitude, start.latitude)` / `(end.longitude, end.latitude)`
  as Dio query parameters, which serialised as `(lon, lat)`; ORS's GET
  `/v2/directions/{profile}` only accepts comma-separated `lon,lat`.
  Regression test `draw_repository_ors_params_test.dart` captures the
  outgoing request through a recording `HttpClientAdapter`.

## 1.3.0

* Customer route wiring for the two map pages (Dart SDK fix-wave
  2026-09-02, route-map rows 16 and 21). Pre-fork `paas_customer` routed
  `/map` -> `ViewMapPage` and `/map_search` -> `MapSearchPage` from its
  host router; after the refork both pages live in this SDK's `lib/` and
  auto_route never generates a route class for an SDK-resident page, so
  base_sdk's `AppRoutes.pushViewMapRoute` (base `add_address` /
  `sellect_address_screen`, marketplace address list and create-shop,
  orders sender/recipient widgets) and `pushMapSearchRoute`
  (`view_map_page`'s own search) threw `StateError` from
  `_HostAppRoutes.noSuchMethod`, and the marketplace `pushNamed('/map')`
  sites found no route.
  * New `templates/routes/map_route_pages.dart` (installed to
    `lib/presentation/routes/map_route_pages.dart`): thin `@RoutePage`
    shells `ViewMapRouteView` / `MapSearchRouteView` wrapping the SDK
    pages, the pattern of core/base's `route_pages.dart`. The view-map
    shell mirrors the page's optional args so the generated `ViewMapRoute`
    carries what the pre-fork route did; `AddressNewModel` is re-exported
    so the generated args class resolves in `app_router.gr.dart`.
  * New `app_type.customer` block declaring `/map` and `/map_search`
    (pre-fork paths kept for deep links) and the `app_routes` entries that
    fill both seams. Customer-scoped, not top level: map_sdk is composed
    into driver/manager/pos too and none has a `/map` path today.
  * `test/manifest_wiring_test.dart` pins the paths, the install target,
    the seam signature (verbatim from base_sdk `app_routes.dart`) and the
    bool-default handling in the `pushViewMapRoute` body.
  * Minor bump (a route is added): manifest 1.2.1 -> 1.3.0, pubspec
    1.0.0 -> 1.1.0.

## 1.2.0

* Floating-nav back conversion (approved design strip section 12, "no
  double back buttons" — base_sdk 1.39.0 / core#125): `MapSearchPage`
  replaces its standalone `PopButton` with the shared `FloatingBottomNav`
  carrying only the leading back segment — one back per screen. Back-only
  (empty tab list) because the host app's root tabs are not reachable
  from this SDK's pushed route. The map-first `ViewMapPage` is left
  untouched (immersive map screen — out of the pattern's scope).

## Unreleased

* Google Places lookups now go through base_sdk's `HttpService` client
  instead of a bare `Dio()` instance, so they ride the standard interceptor
  chain — timing telemetry and ADR-006 trace-id stamping. `requireAuth: false`
  keeps the tenant bearer token off the third-party host (radio_sdk audit-2
  precedent).

## 0.0.1

* TODO: Describe initial release.
