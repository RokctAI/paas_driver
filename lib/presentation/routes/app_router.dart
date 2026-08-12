// ==========================================
// [GENERATED TEMPLATE FILE]
// This file was installed from: base_sdk
// Feel free to modify and customize this code.
// Note: If you edit this file, the SDK installer will detect your changes
// and automatically skip overwriting it during future upgrades.
// ==========================================

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
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
import 'package:driver/presentation/routes/auth_route_pages.dart';
import 'package:driver/presentation/routes/registration_step_pages.dart';
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
        MaterialRoute(path: '/login', page: LoginRoute.page),
        MaterialRoute(path: '/register', page: RegisterRoute.page),
        MaterialRoute(
            path: '/register-confirmation',
            page: RegisterConfirmationRoute.page),
        MaterialRoute(path: '/reset-password', page: ResetPasswordRoute.page),
        MaterialRoute(
            path: '/registration-steps', page: RegistrationStepsRoute.page),
// @generated-routes-end
        // No host-owned routes remain (migration M3): the auth flip lifted
        // auth_sdk's skip_install, so /login, /register,
        // /register-confirmation, /reset-password and /registration-steps
        // now come from auth_sdk's manifest via update_router_table(),
        // exactly like the courier/story/notification routes that moved
        // into their owning SDKs' manifests in M2. The host login page that
        // used to generate LoginRoute here was deleted in the same commit,
        // so there is no duplicate-route collision. delivery_sdk's
        // session_policy (deliveryman -> /home, "*" -> /become-driver
        // keeping the session) took over the role gate the deleted
        // login_notifier.dart implemented.
      ];
}
