// Host composition file (auth_sdk's auth_route_pages.dart precedent).
// delivery_sdk's ported BecomeDriverPage lives in the SDK's lib/src/, and
// auto_route's codegen only generates route classes for @RoutePage widgets
// in the HOST's own lib/ — so this thin wrapper is what actually gets the
// BecomeDriverRoute class generated.
//
// It installs to lib/presentation/pages/auth/become_driver/become_driver.dart
// — the exact path the host's tracked app_router.dart imports today. While
// paas_driver still tracks its own copy there the installer's hash guard
// skips this file; the SDK copy takes over when the host copy is deleted
// (M3, the auth flip — the same commit that retires the legacy in-page
// vehicle form, whose capture now runs as this SDK's `registration_steps`
// vehicle-details slide).

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'package:delivery_sdk/src/common/presentation/pages/become_driver/become_driver.dart'
    as delivery;

@RoutePage(name: 'BecomeDriverRoute')
class BecomeDriverRouteView extends StatelessWidget {
  const BecomeDriverRouteView({super.key});

  @override
  Widget build(BuildContext context) => const delivery.BecomeDriverPage();
}
