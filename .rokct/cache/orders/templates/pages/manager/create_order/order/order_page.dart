import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:${package}/presentation/routes/app_router.dart';
import 'package:base_sdk/src/presentation/components/app_bars/custom_app_bar.dart';
import 'package:base_sdk/src/presentation/components/helper/shop_bordered_avatar.dart';
import 'package:base_sdk/src/presentation/components/loading/loading_list.dart';
import 'package:${package}/presentation/components/orders/food_stock_item.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/buttons/pop_button.dart';
import 'package:base_sdk/src/presentation/components/title_icon.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:orders_sdk/src/manager/application/order/shipping/payment/order_payment_provider.dart';
import 'package:orders_sdk/src/manager/application/order_cart/order_cart_provider.dart';
import 'package:orders_sdk/src/manager/application/order_products/order_products_provider.dart';


@RoutePage(name: 'ManagerOrderRoute')
class OrderPage extends ConsumerStatefulWidget {
  const OrderPage({super.key});

  @override
  ConsumerState<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends ConsumerState<OrderPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        ref.read(orderPaymentProvider.notifier).getCalculate(
              stocks: ref.watch(orderCartProvider).stocks,
              type: 'pickup',
            );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.bgGrey,
      body: Consumer(
        builder: (context, ref, child) {
          final state = ref.watch(orderCartProvider);
          final event = ref.read(orderCartProvider.notifier);
          final paymentState = ref.watch(orderPaymentProvider);
          final paymentNotifier = ref.read(orderPaymentProvider.notifier);
          final productsEvent = ref.read(orderProductsProvider.notifier);
          return Column(
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
                            (LocalStorage.getShopJson()?['translation']?['title'] as String?) ?? '',
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
              Padding(
                padding: REdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 24,
                  bottom: 16,
                ),
                child: TitleAndIcon(
                  title: AppHelpers.getTranslation(TrKeys.orders),
                  rightTitleColor: AppStyle.red,
                  rightTitle: state.stocks.isEmpty
                      ? null
                      : AppHelpers.getTranslation(TrKeys.clearAllOrders),
                  onRightTap: () {
                    event.clearAll();
                    productsEvent.updateProducts(cartStocks: []);
                    paymentNotifier.clearAll();
                    Navigator.pop(context);
                  },
                ),
              ),
              Expanded(
                child: SlidableAutoCloseBehavior(
                  child: paymentState.isCalculateLoading
                      ? const LoadingList(itemPadding: 2)
                      : ListView.builder(
                          padding: REdgeInsets.only(
                            bottom: MediaQuery.paddingOf(context).bottom + 68,
                          ),
                          shrinkWrap: true,
                          itemCount:
                              paymentState.orderCalculate?.stocks?.length ?? 0,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) => FoodStockItem(
                            product:
                                paymentState.orderCalculate?.stocks?[index],
                            onDelete: () => event.deleteStockFromCart(
                              stock:
                                  paymentState.orderCalculate?.stocks?[index] ??
                                      Stock(),
                              updateProducts: (stocks) => productsEvent
                                  .updateProducts(cartStocks: stocks),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterDocked,
      floatingActionButton: Padding(
        padding: REdgeInsets.all(16),
        child: Consumer(
          builder: (context, ref, child) {
            final cartState = ref.watch(orderCartProvider);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const PopButton(heroTag: AppConstants.heroTagAddOrderButton),
                8.horizontalSpace,
                if (cartState.stocks.isNotEmpty)
                  Expanded(
                    child: CustomButton(
                      title: AppHelpers.getTranslation(TrKeys.next),
                      onPressed: () =>
                          context.pushRoute(const ManagerShippingAddressRoute()),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
