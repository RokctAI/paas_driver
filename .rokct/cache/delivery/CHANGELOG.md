## 1.5.0

* Post-compose APK fix round for paas_driver (Build (Smart) run 31635788470,
  87 Dart compile errors), courier vertical aligned with the shared kernel:
  * `ImageCropperMarker` -> base_sdk's `ImageCropperForMarker` (same class,
    base's name; the courier pages already imported base's
    `marker_image_cropper.dart`, only the identifier was stale).
  * Selected-location storage: the legacy host stored a bare `LatLng` under
    `keyAddressSelected`; base's `LocalStorage.setAddressSelected` takes an
    `AddressData`. New `CourierStorage.saveSelectedLocation(LatLng)` wraps
    the coordinates in `AddressData.location`, and reads go through the new
    `AddressData.latitude`/`longitude` getters (base_sdk 1.9.0).
  * Language flow: `LanguageScreen(afterUpdate:)` (host-era widget, never
    composed) -> `EmbeddedWidgets.I.languageScreen(onSave:)` (comms_sdk's
    embedded widget, manager precedent) +
    `AppNotifier.changeLocale` instead of the host's `changeLanguage`.
  * `Delayed` import (base_sdk `tpying_delay.dart`) in the home page.
  * Dropped the host-era no-op args base's helpers never had:
    `AppHelpers.numberFormat(maxLength:)` (self-assigned, dead in the old
    host too) and `showCustomModalBottomSheet(isExpanded:)` (accepted but
    unused in the old host).
  * `ParcelOrder.id` is `String?` in base (commerce/orders consumes it as
    String); the courier notifier's `int?` params now get `int.tryParse` at
    the four call sites.
  * De-consted widgets using brand-mutable `AppStyle.primary`/`shimmerBase`
    (order_history, parcel_history, bottom_sheet_screen, orders_item,
    rate_customer, underline_bordered_text_field, edit_car — commerce#18
    story_page precedent) and const-qualified shop_avarat's default
    `Color` value.
  * Manifest: `confirmPasswordDoesntMatchWithNewPassword` tr_key (used by
    edit_profile_modal, absent from base).

## 1.4.0

* (retro note; shipped without a CHANGELOG entry) `app_routes`
  replaceMainRoute -> /home for driver composes; courier location boot
  hooks (zones PR #14).

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
