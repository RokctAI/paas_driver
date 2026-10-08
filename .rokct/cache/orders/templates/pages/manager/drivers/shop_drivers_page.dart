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

// THE SHOP'S OWN DRIVERS — /load/drivers.
//
// The roster body lives in the SDK
// (`orders_sdk/src/manager/presentation/drivers/`) so it is widget-tested
// at every width; this installed file is the host shell, which is where the
// router lives. It sits under /load because the roster is what the
// issue-a-load driver picker offers: the two screens are one decision, and
// /load/issue has the action that comes here.
//
// One shape at every width. The roster is a short list of names with one
// action each; there is nothing to put in a second plane.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/presentation/adaptive/breakpoints.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:orders_sdk/src/manager/presentation/drivers/shop_drivers_body.dart';

@RoutePage(name: 'ManagerShopDriversRoute')
class ShopDriversPage extends StatelessWidget {
  const ShopDriversPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isLtr = LocalStorage.getLangLtr();
    final bool compact = !windowSizeOf(context).isAtLeastMedium;
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppStyle.surfaceFor(Theme.of(context).brightness),
        body: SafeArea(
          child: Stack(
            children: [
              ShopDriversBody(compact: compact),
              PositionedDirectional(
                end: 16,
                bottom: 16,
                child: FloatingBackPill(
                  back: FloatingNavBack(
                    icon: Remix.arrow_left_wide_fill,
                    label: AppHelpers.getTranslation(TrKeys.back),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
