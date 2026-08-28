# paas_driver fork — REST endpoint handoff

Every endpoint the driver app's Dart client calls today, grouped by the SDK
the calling code is being forked into. This is the handoff to whoever writes
the Frappe side: the Dart is complete and portable, but each path below
currently targets the legacy `/api/v1/...` marketplace surface and needs a
Frappe `/api/method/<app>.api.<fn>` equivalent.

**This list is a deliverable of the fork, not a blocker on it.** Per the
working rule: port the Dart into its SDK, declare the contract on the SDK's
facade, and record what it connects to here. Nothing below is stubbed, faked,
or no-opped.

Source of truth: `paas_driver/lib/infrastructure/repositories/` as of the fork.
`{...}` marks a path parameter. All calls go through the shared dio client;
`requireAuth: true` unless noted.

## Status update — 2026-08-28 driver repoint wave

The driver-facing entries below are no longer live calls. zones#68/#69 and
corporate#70 repointed them onto whitelisted Frappe defs through base_sdk's
universal platform gateway, and this app now vendors those SDK versions
(delivery_sdk 1.11.0, zones_sdk 1.4.0, revenue_sdk 1.4.0):

- **delivery_sdk `orders_repository.dart`** — available/history/current
  order paginates, order detail, and driver review now hit
  `api.delivery_man.get_available_orders`,
  `api.driver_order.get_driver_orders_paginate`,
  `api.delivery_man.get_deliveryman_order_details`, and
  `api.delivery_man.add_deliveryman_order_review`.
- **delivery_sdk `courier_repository.dart`** — driver settings read/write
  (shift toggle included), general info + password, vehicle create/read,
  foreground location reporting, and zone read now hit
  `api.delivery_man.get_deliveryman_settings` /
  `update_deliveryman_settings`, `api.user.update_profile` /
  `update_password`, `api.user.create_request_model` /
  `get_user_request_models`, `api.driver.update_location`, and
  `api.delivery_man.get_deliveryman_zone_polygon`.
- **zones_sdk `delivery_zones_repository.dart`** — zone polygon read/write
  now hit `api.delivery_man.get_deliveryman_zone_polygon` /
  `set_deliveryman_zone_polygon` (plain `[[lat,lng],...]` points; the
  legacy `{"0":lat,"1":lng}` payload shape documented below is retired).
- **revenue_sdk `courier_statistics_repository.dart`** — all three earnings
  reads (including the flagged `seller/` path, confirmed monolith residue)
  now hit `api.delivery_man.get_deliveryman_statistics`,
  `api.delivery_man.get_deliveryman_order_report`, and
  `api.driver_order.get_driver_orders_paginate`.

Both location-reporting callers are covered: the repository's foreground
path and the background-isolate path (now delivery_sdk's
`courier_location_service.dart`, which builds the same gateway request by
hand) both hit `api.driver.update_location`.

Still on the legacy surface after this wave: delivery_sdk's parcel
repository calls, `/api/v1/rest/delivery-vehicle-types`, the
auth/users/comms/settings tables (owned by other SDKs, unchanged here),
and the "pre-existing leftovers" list at the bottom. The tables below are
kept as-recorded for that remaining work.

---

## Note: one caller runs outside the DI graph

`POST /api/v1/dashboard/deliveryman/settings/location` has two callers, not one:

1. `user_repository_impl.dart:404` — `setCurrentLocation()`, the normal
   foreground path, goes through the shared dio client.
2. `main.dart`'s `callbackDispatcher()` — the Workmanager background task,
   which builds its own `Dio` with a hand-assembled `Authorization` header.

The second cannot use a repository: Workmanager runs it in a **separate
isolate** with no GetIt registrations, so nothing in the composed DI graph is
reachable from it. Whoever migrates this endpoint to Frappe must update both,
and the background one needs an isolate-safe way to obtain a token.

Note the payload shapes differ. The repository sends a structured body; the
background task sends `{"location": "{'latitude': '...', 'longitude': '...'}"}`
— a JSON string containing single-quoted pseudo-JSON. Preserved as found;
worth confirming the server accepts both before treating either as canonical.

## Two defects found while compiling this list

### 1. Proof-of-delivery uploads go to the original vendor's server

`orders_repository.dart:187` hardcodes an absolute URL:

```text
https://<upstream-vendor-api-host>/api/v1/dashboard/deliveryman/orders/{orderId}/image
```

Every other call in the app is a relative path resolved against
`AppConstants.baseUrl` (`String.fromEnvironment('BASE_URL')`). This one is
not, so driver proof-of-delivery photos are POSTed to the upstream
vendor's own API host
regardless of how the app is configured — including in production builds. It
is the only such URL in `lib/`.

Treat as a live data-egress issue, not a porting detail. It should become a relative
path when ported into `orders_sdk`.

### 2. Routing is a third-party dependency, not the marketplace backend

`draw_repository_impl.dart:17` calls `/v2/directions/driving-car` with
`AppConstants.routingKey` and `requireAuth: false, routing: true` — an OpenRouteService
-shaped directions API, external to this workspace and to Frappe. It needs no Frappe
equivalent; it needs an entry in the fork-dependency ledger as an accepted external
dependency (or a decision to replace it).

---

## auth_sdk — `auth_repository_impl.dart`

| Method | Path |
| --- | --- |
| POST | `/api/v1/auth/login` |
| POST | `/api/v1/auth/register` |
| POST | `/api/v1/auth/check/phone` |
| POST | `/api/v1/auth/verify/phone` |
| POST | `/api/v1/auth/after-verify` |
| GET | `/api/v1/auth/verify/{verifyCode}` |
| POST | `/api/v1/auth/forgot/email-password` |
| POST | `/api/v1/auth/forgot/email-password/{verifyCode}?email={email}` |
| POST | `/api/v1/auth/forgot/password/confirm` |
| POST | `/api/v1/auth/google/callback` |

auth_sdk already has 11 `/api/method` calls of its own, so most of these
likely have a Frappe counterpart already. Cross-check before porting — prefer
the SDK's existing implementation per the standing "prefer the SDK version"
rule.

## orders_sdk (driver side) — `orders_repository.dart`

<!-- markdownlint-disable MD013 -->
| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/api/v1/dashboard/deliveryman/orders/paginate` | active / available / history (query-varied) |
| GET | `/api/v1/dashboard/deliveryman/orders/paginate?perPage=1&lang=en&current=1` | current order |
| GET | `/api/v1/dashboard/deliveryman/orders/{id}` | order detail |
| POST | `/api/v1/dashboard/deliveryman/order/{orderId}/attach/me` | **driver claims an order** |
| POST | `/api/v1/dashboard/deliveryman/orders/{orderId}/current` | set current order |
| POST | `/api/v1/dashboard/deliveryman/order/{orderId}/status/update` | **advance status** |
| POST | `/api/v1/dashboard/deliveryman/order/{orderId}/status/update?status=canceled` | cancel |
| POST | `/api/v1/dashboard/deliveryman/orders/{orderId}/image` | **proof of delivery** (see defect 1) |
| POST | `/api/v1/dashboard/deliveryman/orders/{orderId}/review` | driver reviews customer |
<!-- markdownlint-enable MD013 -->

## orders_sdk (parcels) — `parcel_repository.dart`

Same shape as orders, for parcel jobs.

<!-- markdownlint-disable MD013 -->
| Method | Path |
| --- | --- |
| GET | `/api/v1/dashboard/deliveryman/parcel-orders/paginate` (active / available / history) |
| GET | `/api/v1/dashboard/deliveryman/parcel-orders{id}` |
| POST | `/api/v1/dashboard/deliveryman/parcel-order/{parcelId}/attach/me` |
| POST | `/api/v1/dashboard/deliveryman/parcel-orders{orderId}/current` |
| POST | `/api/v1/dashboard/deliveryman/parcel-orders/{parcelId}/status/update` |
| POST | `/api/v1/dashboard/deliveryman/parcel-orders/{orderId}/review` |
<!-- markdownlint-enable MD013 -->

Note two paths are missing a `/` before the id (`parcel-orders{id}`,
`parcel-orders{orderId}/current`) — preserved here as written. Verify against
the server before porting; this may be a latent bug.

## delivery_sdk — driver identity, shift state, vehicle, zones

From `user_repository_impl.dart`.

<!-- markdownlint-disable MD013 -->
| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/api/v1/dashboard/deliveryman/settings` | driver detail |
| POST | `/api/v1/dashboard/deliveryman/settings` | create/edit vehicle info |
| POST | `/api/v1/dashboard/deliveryman/settings/online` | **go on/off shift** |
| POST | `/api/v1/dashboard/deliveryman/settings/location` | **location reporting** |
| GET | `/api/v1/rest/delivery-vehicle-types` | vehicle types (no auth) |
| POST | `/api/v1/dashboard/deliveryman/delivery-zones` | **update served zones** |
| GET | `/api/v1/dashboard/deliveryman/delivery-zones` | fetch served zones |
<!-- markdownlint-enable MD013 -->

Payload shape for `POST delivery-zones`, since it is non-obvious:

```json
{ "address": [ { "0": <latitude>, "1": <longitude> }, ... ] }
```

i.e. a polygon as an ordered list of two-element objects keyed `"0"`/`"1"`,
not a `{lat,lng}` object and not a GeoJSON array. Built in
`updateDeliveryZones` (`user_repository_impl.dart:445`) from `List<LatLng>`.

## revenue_sdk — driver earnings

| Method | Path |
| --- | --- |
| GET | `/api/v1/dashboard/deliveryman/order/report` |
| GET | `/api/v1/dashboard/deliveryman/statistics/count` |
| GET | `/api/v1/dashboard/seller/orders/report/paginate` |

The third is a `seller/` path called from the driver app. Confirm it is
intended before porting — it may be residue from the shared-monolith era.

## users_sdk — profile

| Method | Path |
| --- | --- |
| GET | `/api/v1/dashboard/user/profile/show` |
| PUT | `/api/v1/dashboard/user/profile/update` |
| POST | `/api/v1/dashboard/user/profile/password/update` |
| POST | `/api/v1/dashboard/user/profile/firebase/token/update` |
| DELETE | `/api/v1/dashboard/user/profile/delete` |
| GET | `/api/v1/dashboard/user/request-models` |
| POST | `/api/v1/dashboard/user/request-models` |

## comms_sdk — notifications

| Method | Path |
| --- | --- |
| GET | `/api/v1/dashboard/notifications` |
| POST | `/api/v1/dashboard/notifications/read-all` |
| POST | `/api/v1/dashboard/notifications/{id}/read-at` |
| GET | `/api/v1/dashboard/user/profile/notifications-statistic` |

## base_sdk / comms_sdk — app settings

From `settings_repository_impl.dart`. Mostly unauthenticated `rest/` reads.

| Method | Path |
| --- | --- |
| GET | `/api/v1/rest/settings` |
| GET | `/api/v1/rest/currencies` |
| GET | `/api/v1/rest/languages/active` |
| GET | `/api/v1/rest/translations/paginate` |
| POST | `/api/v1/dashboard/galleries` (image upload) |

---

## Pre-existing `/api/v1` leftovers already in the SDKs

Not introduced by this fork; found during the survey. Reported, not touched.

- `commerce/orders/dart/.../parcel_repository.dart:264` — `/api/v1/dashboard/user/order-{name}-process`
- `commerce/orders/dart/.../parcel_repository.dart:285` — `/api/v1/payments/parcel-order/{id}/transactions`
- `zones/delivery/dart/.../delivery_provider.dart:10` — `/api/v1/rest/pages/delivery`
- `core/base/dart/.../about_provider.dart:10` — `/api/v1/rest/pages/about`
- `core/base/dart/.../shop_name_provider.dart:12` — `/api/v1/rest/shops`
- `core/base/dart/.../app_usage_service.dart:36,:90` — `/api/v1/rest/app-usage/{record,stats}`

The base_sdk four have the widest blast radius, since base_sdk is inherited
by every app in the family.
