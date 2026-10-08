## 1.5.0

* Demo runs the REAL `CustomerPoiRepository` through base_sdk 1.73.0's
  `DemoGatewayInterceptor`: `MapSdkDependencies` registers
  `assets/demo/map`, whose `api.poi.get_customer_pois.json` answers an
  empty list (an offline map still stands no unapproved place on itself).
  Deleted `DemoCustomerPoiRepository`. Requires base_sdk 1.73.0.

## 1.4.1

* The map page and map modal now follow the app's light or dark mode: their white cards and black ink use AppStyle.cardFor and inkFor.

## 1.4.0

* The customer map draws the points of interest an administrator stored and
  approved. `poiDataProvider` was created holding an empty list and nothing
  in the fleet ever called its `updatePOIData`, so every one of the page's
  point-of-interest features - the radius filter, the nearest-point label,
  the markers themselves - ran over a list that was empty for the life of
  the app. The map's only pins were the ones the shopper dropped.
  * `CustomerPoiRepository` reads them through base_sdk's universal platform
    gateway on `api.poi.get_customer_pois`, as a guest (the def is
    `allow_guest`), asking for the map's current centre and a radius twice
    the one the page draws within. `ViewMapPage` reads once for the centre
    it opens on and again only when the camera has carried the centre clear
    of the disc already in hand, so a pan costs no call; a read that fails
    leaves the points on screen alone rather than blanking the map.
  * What a shopper may see of a stored point is its name, its type and its
    position. A point also holds contact details, an internal note, the shop
    it belongs to and its creator; none of those is read, mapped or
    reachable from `POIData`, and the mapping is pinned against a row that
    carries them all. A point typed `other` is labelled `label ·
    custom_type`, because "other" on its own names nothing; a point with no
    label falls back to that free text and then to the record id.
  * `DemoCustomerPoiRepository` is the offline twin and serves no points.
    Standing places on an offline map would put somewhere on screen that
    nobody approved and that is not there, which is worse than an empty map
    - a shopper would walk to it. `MapSdkDependencies.register` picks the
    twin from `DemoSession.demoActive`, idempotently, beside the two
    facades it already registered.
  * Marker drawing moves out of the page into `buildPoiMarkers` /
    `poiMarkerIcon`, unchanged except that a pin image which cannot be
    loaded now falls back to the platform's own map pin instead of throwing
    and taking every other marker in the same `Future.wait` down with it.
    That fallback is the live path: no pin ships under `assets/images/poi/`
    in this SDK or in base_sdk, so `CustomerPoiRepository.pinAsset` names
    none rather than guessing a filename that is not in the bundle. A pin
    dropped into `templates/assets/images/poi/` later is named there and
    needs no page change.
  * The page's marker pass now falls back to the camera target the map
    opened on, so points arriving from that first read draw without waiting
    for the shopper to move the map.
  * Tests: the request shape and the guest flag, the label and free-text
    rules, the pin default, coordinates sent as strings, rows dropped for
    want of a position, the envelope forms, the withheld fields, the
    provider's replace-not-append contract, the read window's
    first-build-and-beyond-the-radius decision, and the marker set built
    from a list of points.
  * Depends on `api.poi.get_customer_pois`, which lands with the zone's
    points-of-interest backend; until then the call answers nothing and the
    map draws no stored points, exactly as it does today.

## 1.3.2

* The Google Places API key is sent as an `X-Goog-Api-Key` header instead
  of a `key=` query parameter. `GooglePlacesService.getPlaceDetails` put
  the key in the query string of its GET
  `https://places.googleapis.com/v1/places/{placeId}`, so the credential
  was written down in full by every access log between this client and
  Google - intermediary proxies and gateways, and Google's own - none of
  which we can redact after the fact. Redacting our own logs does not
  reach them; the only fix that does is not putting the secret in the URL.
  * The sibling `getAutocomplete` had always sent the key as a header, so
    this brings the two calls into agreement. Google documents the header
    for the place-details endpoint specifically, alongside the query-
    parameter form it replaces.
  * `fields` and `sessionToken` are not credentials and stay in the query,
    where that endpoint expects them; only the key moves.
  * Regression test `places_service_api_key_test.dart` captures the
    outgoing request through a recording `HttpClientAdapter` on the
    service's `client` seam and asserts the key is absent from the URI,
    the query string and the parameter map, and present as the header -
    for both calls.

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
