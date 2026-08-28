## 1.11.0

* Added an edit pencil to the wallet card on the manager restaurant tab
  (`templates/pages/manager/restaurant/restaurant_page.dart`, approved
  render 2026-08-28): a top-right `Remix.pencil_line` IconButton stacked
  over `BaseWalletCard` in `MerchantWalletSection`, opening the shop-edit
  flow via the exact same `EditRestaurantModal` bottom-sheet invocation as
  the "Restaurant settings" sections row. Overlaid rather than passed
  through the card's `actions` parameter because base_sdk renders
  `actions` as a bottom strip, not top-right.

## 1.10.0

* Rebuilt the manager restaurant tab (`templates/pages/manager/restaurant/
  restaurant_page.dart`) as a host of base_sdk's generic profile page
  (approved profile-host design, section 7, 2026-08-28): standard host
  header, no cover art (the `ShopBanner` sliver is retired from the page;
  the widget file stays installed but unreferenced), and every old content
  block re-registered as a profile section in the old order —
  `merchants.shop_info`, `merchants.working_hours`, `merchants.wallet`,
  `merchants.sections`, plus the `merchants.open_toggle` top-row action
  (the old floating Open/Closed toggle) and a `base.footer` override adding
  the old bottom-nav clearance. The hand-built balance box is replaced by
  base_sdk's `BaseWalletCard` in display-only form (`actions: const []`,
  no history arrow) over the same cached shop-JSON seller wallet source.
  The old floating logout button maps to the host's sign-out affordance
  (registry `onLogout`, the LogoutModal's confirmed branch). Tab wiring is
  untouched: `main_page.dart` still imports the page directly and it
  declares no route. Requires base_sdk >= 1.32.0.

## 1.9.4

* Routed the broken direct `/api/method/paas.api.*` call sites through
  base_sdk's universal platform gateway (`PlatformGateway`, fleet rule
  2026-08-15): shops repository (`api.shop.search_shops`/`get_shops`/
  `get_nearby_shops`/`get_shops_by_ids`/`create_shop`/`get_shops_recommend`,
  cross-module `api.cart.join_order`, `api.delivery.check_delivery_zone`,
  `api.story.get_story`, `api.tag.get_tags`, `api.product.get_suggest_price`)
  and the offline shop-create sync handler (`api.shop.create_shop`,
  idempotency header preserved). Fixed payload keys that never matched the
  backend kwargs: get_shops_by_ids `shop_ids`, join_order
  `cart_id`/`user_name`, create_shop wrapped in `shop_data`. Registered the
  missing `api.seller_operations.get_seller_sections`/`get_seller_tables` and
  `api.seller_product.create_product` whitelisted-method keys in
  merchants/frappe/manifest.json. Recorded endpoint gaps
  (get_shop_by_uuid/get_shop_branch/get_pickup_shops) are untouched.

## 1.9.3

* Freezed 3 follow-through (PR #28 missed the templates dir): the installed
  `merchants_adapters.dart` template now imports
  `package:base_sdk/src/handlers/api_result.dart` directly so its
  `ApiResult.when` call site resolves against freezed-3 base_sdk. No behavior
  change.

## 1.9.1

* Sliced `manager/infrastructure/models/` into the canonical `data/` and `response/` subfolders: moved `sections_tables.dart` to `models/data/` and `my_shop_response.dart` to `models/response/`. Updated all imports. No API changes.

## 1.9.0

* Driver migration S-D6: adopted paas_driver's intro-story block (`driver/application/story` + story page + `/story` route). See manifest comment for details.
