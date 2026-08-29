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
