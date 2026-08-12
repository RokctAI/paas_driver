## 1.3.0

* Courier vertical build-out (S-D3 of the paas_driver lib-regenerable plan):
  `lib/src/driver/` role slice ported from paas_driver main — application
  slices (home map, orders, parcels, push-order, driver, vehicles, profile),
  the Laravel deliveryman repositories moved AS-IS (decision D2:
  `CourierOrdersRepository`, `CourierParcelRepository`, `CourierRepository`
  over `/api/v1/dashboard/deliveryman/*`), courier-only models, and
  `DriverDeliveryDependencies` (di hook, revenue_sdk precedent).
* Driver templates installed to the exact host paths paas_driver's tracked
  router/pages import today: pages (home ×10, orders, order history, parcels
  ×3, parcel history, push order, profile ×7 incl. the new
  `courier_statistics_provider.dart` revenue seam, become-driver shell),
  components ×14 (incl. restaurant_item / product_item / maps_list per
  decision D3 and seven custodianship copies of driver-only widgets), and
  `delivery_adapters.dart` (vehicle-capture adapter).
* Manifest: real `home_page` template (the key existed since 1.2.0 without
  the file), `home_sdk` flag, `app_type.driver` routes for
  /home /orders /order-history /parcels /parcel-history /profile
  /become-driver, `session_policy` (deliveryman → /home, `*` fallback →
  /become-driver pending decision D1 / auth_sdk S-D4), the
  `delivery.vehicle_details` registration step (`VehicleDetailsSlide`,
  decision D5 scope: the legacy become-driver form's fields only),
  `app_routes` (replaceLoginRoute), 31 courier `tr_keys`, `asset_keys`
  (pngMyLocation, svgBalance) + custodianship asset copies.

## 1.2.0

* (pre-existing) delivery points repository, delivery/become-driver common
  pages, splash/marker custodianship assets.
