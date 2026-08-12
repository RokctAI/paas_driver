// Host-side route shells for base_sdk's initial pages.
//
// auto_route's generator only scans the host package, so SDK-resident pages
// are wrapped in thin @RoutePage shells here. Feature SDKs contribute their
// own shells through their manifest installs when they own routed pages.
//
// Migration stage M2 restored the full base_sdk template shell set: the
// app's own splash and no-connection pages under lib/presentation/pages/
// are deleted (base_sdk owns them now), so SplashRoute and NoConnectionRoute
// are shelled here again. LoginRoute is deliberately NOT shelled here:
// since the auth flip (M3) it is generated from auth_sdk's installed
// auth_route_pages.dart shells, the same mechanism as every other
// SDK-routed page.
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'package:base_sdk/src/presentation/pages/initial/closed/closed_page.dart'
    as pages;
import 'package:base_sdk/src/presentation/pages/initial/no_connection/no_connection_page.dart'
    as pages;
import 'package:base_sdk/src/presentation/pages/initial/splash/splash_page.dart'
    as pages;
import 'package:base_sdk/src/presentation/pages/initial/ui_type/ui_type_page.dart'
    as pages;

/// Host route shell for [pages.SplashPage] (base_sdk-resident page).
@RoutePage(name: 'SplashRoute')
class SplashRouteView extends StatelessWidget {
  const SplashRouteView({super.key});

  @override
  Widget build(BuildContext context) => const pages.SplashPage();
}

/// Host route shell for [pages.NoConnectionPage] (base_sdk-resident page).
@RoutePage(name: 'NoConnectionRoute')
class NoConnectionRouteView extends StatelessWidget {
  const NoConnectionRouteView({super.key});

  @override
  Widget build(BuildContext context) => const pages.NoConnectionPage();
}

/// Host route shell for [pages.ClosedPage] (base_sdk-resident page).
@RoutePage(name: 'ClosedRoute')
class ClosedRouteView extends StatelessWidget {
  const ClosedRouteView({super.key});

  @override
  Widget build(BuildContext context) => const pages.ClosedPage();
}

/// Host route shell for [pages.UiTypePage] (base_sdk-resident page).
@RoutePage(name: 'UiTypeRoute')
class UiTypeRouteView extends StatelessWidget {
  final bool isBack;
  const UiTypeRouteView({super.key, this.isBack = false});

  @override
  Widget build(BuildContext context) => pages.UiTypePage(isBack: isBack);
}
