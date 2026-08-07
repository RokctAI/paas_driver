// ==========================================
// [GENERATED TEMPLATE FILE]
// This file was installed from: base_sdk
// Feel free to modify and customize this code.
// Note: If you edit this file, the SDK installer will detect your changes
// and automatically skip overwriting it during future upgrades.
// ==========================================

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
// Host pages referenced by the routes below. The .gr.dart part shares this
// library's imports, so every @RoutePage class routed here must be visible.
import 'package:driver/presentation/pages/pages.dart';
import 'package:driver/presentation/pages/parcel/parcels_page.dart';
import 'package:driver/presentation/pages/parcels_history/parcel_history.dart';
import 'package:driver/presentation/pages/auth/become_driver/become_driver.dart';
// @generated-imports-start
import 'package:driver/presentation/pages/profile/delivery_zone/delivery_zone_page.dart';
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
    MaterialRoute(path: '/delivery-zone', page: DriverDeliveryZoneRoute.page),
// @generated-routes-end
        // Host-owned routes, deliberately OUTSIDE the generated markers:
        // update_router_table() rewrites everything between them on every
        // compose, and no SDK manifest declares these pages yet — they are
        // the app's own (lib/presentation/pages/). Each should migrate into
        // its owning SDK's manifest (or composer.json "host_routes") as its
        // feature moves out of the app.
        //
        // /login stays host-owned too: auth_sdk's manifest declares /login..
        // /reset-password via its auth_route_pages.dart shells, but this app
        // still owns its login page, whose @RoutePage already generates
        // LoginRoute — installing auth_sdk's shells would duplicate the name.
        // The auth_sdk routes take over when the app's auth pages migrate.
        CupertinoRoute(path: '/login', page: LoginRoute.page),
        CupertinoRoute(path: '/income', page: IncomeRoute.page),
        CupertinoRoute(path: '/home', page: HomeRoute.page),
        CupertinoRoute(path: '/story', page: StoryRoute.page),
        CupertinoRoute(path: '/profile', page: ProfileRoute.page),
        CupertinoRoute(
            path: '/list-notification', page: NotificationListRoute.page),
        CupertinoRoute(path: '/order-history', page: OrderHistoryRoute.page),
        CupertinoRoute(path: '/parcel-history', page: ParcelHistoryRoute.page),
        CupertinoRoute(path: '/orders', page: OrdersRoute.page),
        CupertinoRoute(path: '/parcels', page: ParcelsRoute.page),
        CupertinoRoute(path: '/become-driver', page: BecomeDriverRoute.page),
      ];
}
