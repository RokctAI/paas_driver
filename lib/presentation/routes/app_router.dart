import 'package:auto_route/auto_route.dart';

import 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    CupertinoRoute(path: '/', page: SplashRoute.page),
    CupertinoRoute(path: '/no-connection', page: NoConnectionRoute.page),
    CupertinoRoute(path: '/login', page: LoginRoute.page),
    CupertinoRoute(path: '/income', page: IncomeRoute.page),
    CupertinoRoute(path: '/home', page: HomeRoute.page),
    CupertinoRoute(path: '/story', page: StoryRoute.page),
    CupertinoRoute(path: '/profile', page: ProfileRoute.page),
    CupertinoRoute(
      path: '/list-notification',
      page: NotificationListRoute.page,
    ),
    CupertinoRoute(path: '/order-history', page: OrderHistoryRoute.page),
    CupertinoRoute(path: '/parcel-history', page: ParcelHistoryRoute.page),
    CupertinoRoute(path: '/orders', page: OrdersRoute.page),
    CupertinoRoute(path: '/parcels', page: ParcelsRoute.page),
    CupertinoRoute(path: '/become-driver', page: BecomeDriverRoute.page),
    CupertinoRoute(path: '/delivery-zone', page: DeliveryZoneRoute.page),
  ];
}
