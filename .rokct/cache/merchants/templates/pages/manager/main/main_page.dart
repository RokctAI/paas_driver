// Copyright (c) 2026 RokctAI
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:proste_indexed_stack/proste_indexed_stack.dart';

import 'package:${package}/presentation/theme/theme.dart';
// Tab pages and create-modals install from their owning SDKs into these host
// paths: orders_sdk -> pages/orders + the ManagerCreateOrderRoute POS flow,
// products_sdk -> pages/foods (+ create modals), merchants_sdk -> the
// restaurant tab. This shell compiles once those app_type.manager installs
// have landed alongside it in the composed app.
import 'package:${package}/presentation/pages/orders/orders_home_page.dart';
import 'package:${package}/presentation/pages/foods/foods_page.dart';
import 'package:${package}/presentation/pages/foods/create/create_product_modal.dart';
import 'package:${package}/presentation/pages/foods/addons/create/create_addon_modal.dart';
import 'package:${package}/presentation/pages/foods/extras/create/create_extras_group_modal.dart';
import 'package:${package}/presentation/pages/restaurant/restaurant_page.dart';
import 'package:${package}/presentation/routes/app_router.dart';
import 'package:${package}/presentation/pages/main/widgets/bottom_navigator_item.dart';
import 'package:${package}/presentation/pages/main/widgets/buttons_bouncing_effect.dart';
import 'package:merchants_sdk/src/manager/application/main/main_provider.dart';
import 'package:products_sdk/src/manager/application/foods/food_tabs_provider.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/presentation/components/blur_wrap.dart';
import 'package:base_sdk/src/presentation/components/keyboard_dismisser.dart';
import 'package:base_sdk/src/presentation/components/custom_network_image.dart';

@RoutePage(name: 'MainRoute')
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<IndexedStackChild> list = [
    IndexedStackChild(child: const OrdersHomePage(), preload: true),
    IndexedStackChild(child: const FoodsPage(), preload: false),
    IndexedStackChild(child: const RestaurantPage(), preload: false),
  ];

  @override
  void initState() {
    FirebaseMessaging.instance.requestPermission(
      sound: true,
      alert: true,
      badge: false,
    );
    FirebaseMessaging.onBackgroundMessage((RemoteMessage message) async {
      await Firebase.initializeApp();
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {});
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppHelpers.showCheckTopSnackBarDone(
        // ignore: use_build_context_synchronously
        context,
        "${AppHelpers.getTranslation(TrKeys.id)} #${message.notification?.title} ${message.notification?.body}",
      );
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLtr = LocalStorage.getLangLtr();
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: KeyboardDismisser(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? child) =>
                ProsteIndexedStack(
                  index: ref.watch(mainProvider).selectedIndex,
                  children: list,
                ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: Consumer(
            builder: (context, ref, child) {
              final state = ref.watch(mainProvider);
              final event = ref.read(mainProvider.notifier);
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BlurWrap(
                    radius: BorderRadius.circular(100.r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      decoration: BoxDecoration(
                        color: AppStyle.bottomNavigationBarColor.withOpacity(
                          0.6,
                        ),
                        borderRadius: BorderRadius.circular(100.r),
                      ),
                      height: 60.r,
                      child: Padding(
                        padding: REdgeInsets.only(
                          right: 10,
                          left: !state.isScrolling ? 10 : 0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            BottomNavigatorItem(
                              isScrolling: state.isScrolling,
                              selectItem: () => event.selectIndex(0),
                              currentIndex: state.selectedIndex,
                              index: 0,
                              selectIcon: Remix.file_list_2_fill,
                              unSelectIcon: Remix.file_list_2_line,
                            ),
                            BottomNavigatorItem(
                              isScrolling: state.isScrolling,
                              selectItem: () => event.selectIndex(1),
                              index: 1,
                              currentIndex: state.selectedIndex,
                              selectIcon: Remix.restaurant_fill,
                              unSelectIcon: Remix.restaurant_line,
                            ),
                            _profileItem(() {
                              event.selectIndex(2);
                              event.changeScrolling(false);
                            }, state.selectedIndex),
                          ],
                        ),
                      ),
                    ),
                  ),
                  state.selectedIndex != 2
                      ? ButtonsBouncingEffect(
                          child: Hero(
                            tag: AppConstants.heroTagAddOrderButton,
                            child: GestureDetector(
                              onTap: () {
                                if (state.selectedIndex == 0) {
                                  context.pushRoute(
                                    const ManagerCreateOrderRoute(),
                                  );
                                } else {
                                  _showModalBasedOnFoodTab(context, ref);
                                }
                              },
                              child: Container(
                                margin: EdgeInsetsDirectional.only(start: 8.r),
                                width: 56.r,
                                height: 56.r,
                                // Not const: AppStyle.primary is a getter
                                // (brand-injectable), unlike the legacy
                                // Style.primary constant.
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppStyle.primary,
                                ),
                                child: Icon(
                                  Remix.add_line,
                                  size: 26.r,
                                  color: AppStyle.blackColor,
                                ),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showModalBasedOnFoodTab(BuildContext context, WidgetRef ref) {
    final foodTabIndex = ref.read(foodTabsProvider).selectedIndex;
    Widget modal;
    if (foodTabIndex == 0) {
      modal = const CreateProductModal();
    } else if (foodTabIndex == 1) {
      modal = const CreateAddonModal();
    } else {
      modal = const CreateExtrasGroupModal();
    }

    AppHelpers.showCustomModalBottomSheet(
      paddingTop: MediaQuery.of(context).padding.top + 64.h,
      context: context,
      modal: modal,
      isDarkMode: false,
    );
  }

  GestureDetector _profileItem(Function() onTap, int index) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.r,
        height: 40.r,
        margin: EdgeInsets.only(left: 12.r),
        decoration: BoxDecoration(
          border: Border.all(
            color: index == 2 ? AppStyle.primary : AppStyle.transparent,
            width: 2.w,
          ),
          shape: BoxShape.circle,
        ),
        child: CustomNetworkImage(
          url: LocalStorage.getShopJson()?['logo_img'] as String?,
          width: 40.r,
          height: 40.r,
          radius: 20.r,
        ),
      ),
    );
  }
}
