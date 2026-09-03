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

// Host-side route shells for map_sdk's customer pages (the pattern of
// core/base's route_pages.dart and auth_sdk's auth_route_pages.dart, ADR-005).
//
// auto_route's generator only scans the HOST package: ViewMapPage and
// MapSearchPage are @RoutePage-annotated inside map_sdk, but no route class
// is ever generated for a page defined in a path-dependency SDK. These thin
// wrappers are what the host's build generates ViewMapRoute / MapSearchRoute
// from. map_sdk's manifest installs this file to
// lib/presentation/routes/map_route_pages.dart, points its
// app_type.customer.routes entries at it, and fills base_sdk's
// AppRoutes.pushViewMapRoute / pushMapSearchRoute seams with the generated
// classes. Paths keep the pre-fork values (/map, /map_search) so the
// marketplace pushNamed sites and any deep links keep resolving.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'package:base_sdk/src/models/data/address_new_data.dart';
import 'package:map_sdk/src/common/presentation/pages/view_map/map_search_page.dart'
    as pages;
import 'package:map_sdk/src/common/presentation/pages/view_map/view_map_page.dart'
    as pages;

// Re-exported, not just imported: the generated app_router.gr.dart shares
// app_router.dart's library scope, and ViewMapRoute's generated args class
// references AddressNewModel by type - it must be visible there.
export 'package:base_sdk/src/models/data/address_new_data.dart';

/// Host route shell for [pages.ViewMapPage] (map_sdk-resident page). The
/// constructor mirrors the page's own so the generated ViewMapRoute carries
/// the same optional args the pre-fork `/map` route did.
@RoutePage(name: 'ViewMapRoute')
class ViewMapRouteView extends StatelessWidget {
  final bool isShopLocation;
  final bool isPop;
  final bool isParcel;
  final String? shopId;
  final int? indexAddress;
  final AddressNewModel? address;

  const ViewMapRouteView({
    super.key,
    this.isParcel = false,
    this.isPop = true,
    this.isShopLocation = false,
    this.shopId,
    this.indexAddress,
    this.address,
  });

  @override
  Widget build(BuildContext context) => pages.ViewMapPage(
        isParcel: isParcel,
        isPop: isPop,
        isShopLocation: isShopLocation,
        shopId: shopId,
        indexAddress: indexAddress,
        address: address,
      );
}

/// Host route shell for [pages.MapSearchPage] (map_sdk-resident page).
@RoutePage(name: 'MapSearchRoute')
class MapSearchRouteView extends StatelessWidget {
  const MapSearchRouteView({super.key});

  @override
  Widget build(BuildContext context) => const pages.MapSearchPage();
}
