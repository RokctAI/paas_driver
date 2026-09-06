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

import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:${package}/presentation/routes/app_router.dart';
import 'package:${package}/presentation/pages/create_order/order/widgets/order_pane.dart';
import 'package:base_sdk/src/presentation/components/app_bars/custom_app_bar.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/presentation/components/helper/shop_bordered_avatar.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:orders_sdk/src/manager/application/order_cart/order_cart_provider.dart';

@RoutePage(name: 'ManagerOrderRoute')
class OrderPage extends ConsumerStatefulWidget {
  const OrderPage({super.key});

  @override
  ConsumerState<OrderPage> createState() => _OrderPageState();
}

/// Phone flow only (frame 37d): the cart pushed as its own route by the
/// "Ordering · total" continuation (690). At plane widths this route is
/// never pushed — the cart pane is already on stage inside the walk-in
/// spread (section 37 decision (a), locked). The body (title, calculated
/// stock list, subtotal, recalculation on entry) lives in [OrderPane].
/// The shipped pop | Next pair is re-housed in the two-state language:
/// Next at the START, the corner Back pill (347) at the END.
class _OrderPageState extends ConsumerState<OrderPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.surfaceDark,
      body: Stack(
        children: [
          Column(
            children: [
              CustomAppBar(
                bottomPadding: 16.h,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ShopBorderedAvatar(
                      size: 40,
                      imageSize: 33,
                      borderRadius: 20,
                      // base_sdk's LocalStorage keeps the shop as raw JSON (getShopJson) -
                      // same access pattern as merchants_sdk's main_page.
                      imageUrl: LocalStorage.getShopJson()?['logo_img'] as String?,
                    ),
                    12.horizontalSpace,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            (LocalStorage.getShopJson()?['translation']?['title']
                                    as String?) ??
                                '',
                            style: AppStyle.interSemi(size: 18.sp),
                          ),
                          Text(
                            (LocalStorage.getShopJson()?['translation']
                                    ?['description'] as String?) ??
                                '',
                            style: AppStyle.interRegular(
                              size: 12.sp,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Expanded(child: OrderPane()),
            ],
          ),
          // Next (685) at the START, the corner Back pill (347) at the END
          // — the settled two-state rule for a pushed page on one plane.
          PositionedDirectional(
            start: 16,
            end: 16,
            bottom: 16,
            child: SafeArea(
              child: Consumer(
                builder: (context, ref, child) {
                  final cartState = ref.watch(orderCartProvider);
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (cartState.stocks.isNotEmpty)
                        Expanded(
                          child: CustomButton(
                            title: AppHelpers.getTranslation(TrKeys.next),
                            onPressed: () => context.pushRoute(
                              ManagerShippingAddressRoute(),
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      8.horizontalSpace,
                      FloatingBackPill(
                        back: FloatingNavBack(
                          icon: Remix.arrow_left_wide_fill,
                          label: AppHelpers.getTranslation(TrKeys.back),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
