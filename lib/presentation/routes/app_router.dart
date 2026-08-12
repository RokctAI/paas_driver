// ==========================================
// [GENERATED TEMPLATE FILE]
// This file was installed from: base_sdk
// Feel free to modify and customize this code.
// Note: If you edit this file, the SDK installer will detect your changes
// and automatically skip overwriting it during future upgrades.
// ==========================================

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
// The one host page still routed by hand (its @RoutePage generates
// LoginRoute). The .gr.dart part shares this library's imports, so every
// @RoutePage class routed here must be visible; the SDK-installed pages'
// imports are (re)written into the generated block on every compose.
import 'package:driver/presentation/pages/auth/login/login_page.dart';
// @generated-imports-start
import 'package:driver/presentation/pages/auth/become_driver/become_driver.dart';
import 'package:driver/presentation/pages/calc/calculator_page.dart';
import 'package:driver/presentation/pages/home/home_page.dart';
import 'package:driver/presentation/pages/income/income_page.dart';
import 'package:driver/presentation/pages/order_history/order_history.dart';
import 'package:driver/presentation/pages/orders/orders_page.dart';
import 'package:driver/presentation/pages/parcel/parcels_page.dart';
import 'package:driver/presentation/pages/parcels_history/parcel_history.dart';
import 'package:driver/presentation/pages/profile/delivery_zone/delivery_zone_page.dart';
import 'package:driver/presentation/pages/profile/notification_list_page.dart';
import 'package:driver/presentation/pages/profile/profile_page.dart';
import 'package:driver/presentation/pages/stores/story_page.dart';
import 'package:driver/presentation/routes/route_pages.dart';
// @generated-imports-end

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
// @generated-routes-start
        MaterialRoute(path: '/', page: SplashRoute.page),
        MaterialRoute(path: '/no-connection', page: NoConnectionRoute.page),
        MaterialRoute(path: '/closed', page: ClosedRoute.page),
        MaterialRoute(path: '/ui-type', page: UiTypeRoute.page),
        CupertinoRoute(path: '/home', page: HomeRoute.page),
        CupertinoRoute(path: '/orders', page: OrdersRoute.page),
        CupertinoRoute(path: '/order-history', page: OrderHistoryRoute.page),
        CupertinoRoute(path: '/parcels', page: ParcelsRoute.page),
        CupertinoRoute(path: '/parcel-history', page: ParcelHistoryRoute.page),
        CupertinoRoute(path: '/profile', page: ProfileRoute.page),
        CupertinoRoute(path: '/become-driver', page: BecomeDriverRoute.page),
        CupertinoRoute(
            path: '/list-notification', page: NotificationListRoute.page),
        MaterialRoute(
            path: '/delivery-zone', page: DriverDeliveryZoneRoute.page),
        MaterialRoute(path: '/income', page: DriverIncomeRoute.page),
        CupertinoRoute(path: '/story', page: StoryRoute.page),
        CupertinoRoute(path: '/calc', page: CalculatorRoute.page),
// @generated-routes-end
        // The single remaining host-owned route, deliberately OUTSIDE the
        // generated markers: update_router_table() rewrites everything
        // between them on every compose. The nine courier/story/notification
        // routes that used to sit here moved into their owning SDKs'
        // manifests in migration stage M2 (delivery_sdk: /home /orders
        // /order-history /parcels /parcel-history /profile /become-driver;
        // comms_sdk: /list-notification; merchants_sdk: /story) - the
        // recompose regenerates them inside the markers above.
        //
        // /login stays host-owned until the auth flip (M3): this app still
        // owns its login page, whose @RoutePage already generates LoginRoute
        // - auth_sdk's auth_route_pages.dart shells would duplicate the
        // name. auth_sdk is composed with its installer skipped
        // ("skip_install" in composer.json), so recomposing keeps its
        // /login../reset-password routes out of the generated block durably.
        // The flip lifts skip_install (paired protocol PR), deletes the host
        // auth vertical, and drops this line - delivery_sdk's session_policy
        // (deliveryman -> /home, "*" -> /become-driver) then takes over the
        // role gate that login_notifier.dart implements today.
        CupertinoRoute(path: '/login', page: LoginRoute.page),
      ];
}
