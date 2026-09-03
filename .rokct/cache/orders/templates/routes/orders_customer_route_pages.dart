// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.


// Host composition file (ADR-005): thin @RoutePage shells for orders_sdk's
// CUSTOMER pages. auto_route's codegen only generates route classes for
// @RoutePage widgets that live in the HOST's own lib/, never inside a
// path-dependency SDK's lib/, so the manifest's app_type.customer "routes"
// point at THIS file (installed to lib/presentation/routes/) rather than at
// the SDK page classes directly - the same pattern as marketplace_sdk's
// marketplace_route_pages.dart and auth_sdk's auth_route_pages.dart.
//
// Route names and paths are the pre-fork paas_customer ones (fix-wave
// 2026-09-02 route map, rows 11/13/23/35/36/38/39) so deep links, push
// payloads and base_sdk's AppRoutes seam (`pushOrdersListRoute`,
// `pushOrderRoute`, `pushOrderProgressRoute`, `pushParcelRoute`,
// `pushInfoRoute`, `pushParcelListRoute`, `pushParcelProgressRoute` and the
// replace twins, filled by this SDK's manifest "app_routes") keep working.
// The manager flavour's ManagerOrderRoute (/order) lives in a different
// app_type block and never composes alongside these.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'package:orders_sdk/src/common/presentation/pages/order/order_screen/order_progress_screen.dart';
import 'package:orders_sdk/src/common/presentation/pages/order/order_screen/order_screen.dart';
import 'package:orders_sdk/src/common/presentation/pages/order/orders_page.dart';
import 'package:orders_sdk/src/common/presentation/pages/parcel/parcel_list_page.dart';
import 'package:orders_sdk/src/common/presentation/pages/parcel/parcel_order_page.dart';
import 'package:orders_sdk/src/common/presentation/pages/parcel/parcel_page.dart';
import 'package:orders_sdk/src/common/presentation/pages/parcel/widgets/info_screen.dart';

/// `/order` - the customer's active / history / refund order tabs.
@RoutePage(name: 'OrdersListRoute')
class OrdersListRouteView extends StatelessWidget {
  const OrdersListRouteView({super.key});

  @override
  Widget build(BuildContext context) => const OrdersListPage();
}

/// `/orderScreen` - the checkout (order type, address, payment, confirm).
@RoutePage(name: 'OrderRoute')
class OrderRouteView extends StatelessWidget {
  const OrderRouteView({super.key});

  @override
  Widget build(BuildContext context) => const OrderPage();
}

/// `/order_progress` - one order's live status. `orderId` also rides as a
/// query parameter so a notification deep link (`/order_progress?orderId=`)
/// resolves without a typed push.
@RoutePage(name: 'OrderProgressRoute')
class OrderProgressRouteView extends StatelessWidget {
  final String? orderId;

  const OrderProgressRouteView({
    super.key,
    @QueryParam('orderId') this.orderId,
  });

  @override
  Widget build(BuildContext context) => OrderProgressPage(orderId: orderId);
}

/// `/parcel_page` - the door-to-door parcel order form.
@RoutePage(name: 'ParcelRoute')
class ParcelRouteView extends StatelessWidget {
  final bool isBackButton;

  const ParcelRouteView({super.key, this.isBackButton = true});

  @override
  Widget build(BuildContext context) => ParcelPage(isBackButton: isBackButton);
}

/// `/info_screen` - the parcel onboarding info slides (`index` selects the
/// slide; the page's own "next" replaces itself with `index + 1`).
@RoutePage(name: 'InfoRoute')
class InfoRouteView extends StatelessWidget {
  final int index;

  const InfoRouteView({super.key, @QueryParam('index') this.index = 0});

  @override
  Widget build(BuildContext context) => InfoPage(index: index);
}

/// `/parcel_list_page` - the customer's active / history parcel tabs.
@RoutePage(name: 'ParcelListRoute')
class ParcelListRouteView extends StatelessWidget {
  const ParcelListRouteView({super.key});

  @override
  Widget build(BuildContext context) => const ParcelListPage();
}

/// `/parcel_progress_page` - one parcel's live status.
@RoutePage(name: 'ParcelProgressRoute')
class ParcelProgressRouteView extends StatelessWidget {
  final String? parcelId;

  const ParcelProgressRouteView({
    super.key,
    @QueryParam('parcelId') this.parcelId,
  });

  @override
  Widget build(BuildContext context) => ParcelProgressPage(parcelId: parcelId);
}
