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

import 'dart:async';
import 'package:base_sdk/src/navigation/embedded_widgets.dart';
import 'package:orders_sdk/src/common/application/live/active_order_tracker.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:base_sdk/src/application/order/order_notifier.dart';
import 'package:base_sdk/src/application/order/order_provider.dart';
import 'package:base_sdk/src/application/payment_methods/payment_provider.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:base_sdk/src/models/data/order_active_model.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/app_bars/common_app_bar.dart';
import 'package:base_sdk/src/presentation/components/keyboard_dismisser.dart';
import 'package:base_sdk/src/presentation/components/loading.dart';
import 'package:base_sdk/src/presentation/components/shop_avarat.dart';
import 'package:base_sdk/src/presentation/components/title_icon.dart';
import 'package:orders_sdk/src/common/presentation/pages/order/order_check/order_check.dart';
import 'package:orders_sdk/src/common/presentation/pages/order/order_check/widgets/rating_page.dart';
import 'package:orders_sdk/src/common/presentation/pages/order/order_type/widgets/order_map.dart';
// [refork] embed via EmbeddedWidgets
import 'package:base_sdk/src/presentation/theme/app_style.dart';

import 'package:base_sdk/src/application/order/order_state.dart';
import 'package:base_sdk/src/presentation/components/buttons/pop_button.dart';
import 'package:orders_sdk/src/common/presentation/pages/order/order_check/widgets/refund_info.dart';
import 'package:orders_sdk/src/common/presentation/pages/order/order_screen/widgets/order_status.dart';

@RoutePage()
class OrderProgressPage extends ConsumerStatefulWidget {
  final String? orderId;

  const OrderProgressPage({super.key, this.orderId});

  @override
  ConsumerState<OrderProgressPage> createState() => _OrderProgressPageState();
}

class _OrderProgressPageState extends ConsumerState<OrderProgressPage> {
  RefreshController refreshController = RefreshController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late OrderNotifier event;
  late bool isLtr;

  /// The app-wide tracker polls this order (15s on the way, 120s
  /// otherwise, never in the background) and feeds the live activity;
  /// this screen only refreshes its own view when a poll saw a change.
  late final ActiveOrderTracker _tracker;
  StreamSubscription<OrderActiveModel>? _updates;

  String get _orderId => widget.orderId ?? "";

  @override
  void initState() {
    super.initState();
    _tracker = ref.read(activeOrderTrackerProvider);
    _updates = _tracker.updates
        .where((o) => o.id == _orderId)
        .listen(_onTrackerUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderProvider.notifier).showOrder(context, _orderId, false);
      ref.read(paymentProvider.notifier).fetchPayments(context);
      _tracker.track(_orderId, pin: true);
    });
  }

  /// Reload the screen's order only when the tracker's poll differs from
  /// what is shown (status or driver), so there is no second poll.
  void _onTrackerUpdate(OrderActiveModel polled) {
    if (!mounted) return;
    final shown = ref.read(orderProvider).orderData;
    if (shown == null) return;
    final statusChanged = AppHelpers.getOrderStatus(shown.status) !=
        AppHelpers.getOrderStatus(polled.status);
    final driverChanged = shown.deliveryMan?.id != polled.deliveryMan?.id;
    if (statusChanged || driverChanged) {
      ref.read(orderProvider.notifier).showOrder(context, _orderId, true);
    }
  }

  @override
  void dispose() {
    _updates?.cancel();
    _tracker.release(_orderId);
    refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderProvider);
    final event = ref.read(orderProvider.notifier);
    final isLtr = LocalStorage.getLangLtr();
    ref.listen(orderProvider, (previous, next) {
      if (AppHelpers.getOrderStatus(next.orderData?.status ?? "") ==
              OrderStatus.delivered &&
          !(next.orderData?.review != null || next.orderData?.tips != null) &&
          previous?.orderData?.status != next.orderData?.status) {
        AppHelpers.showCustomModalBottomSheet(
          context: context,
          modal: RatingPage(totalPrice: next.orderData?.totalPrice),
          isDarkMode: Theme.of(context).brightness == Brightness.dark,
        );
      }
    });

    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: KeyboardDismisser(
        child: Scaffold(
          key: _scaffoldKey,
          resizeToAvoidBottomInset: false,
          backgroundColor: AppStyle.surfaceFor(Theme.of(context).brightness),
          body: state.isLoading
              ? const Loading()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _appBar(context, state),
                    _orderScreen(event, context, state),
                  ],
                ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: _bottom(context),
        ),
      ),
    );
  }

  Widget _bottom(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(children: [const PopButton(), 16.horizontalSpace]),
    );
  }

  Widget _orderScreen(
    OrderNotifier event,
    BuildContext context,
    OrderState state,
  ) {
    return Expanded(
      child: SmartRefresher(
        enablePullDown: true,
        enablePullUp: false,
        controller: refreshController,
        onRefresh: () {
          event.showOrder(context, state.orderData?.id ?? "", true);
          unawaited(_tracker.refresh(_orderId));
          refreshController.refreshCompleted();
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              16.verticalSpace,
              state.orderData?.refunds?.isNotEmpty ?? false
                  ? RefundInfoScreen(
                      refundModel: state.orderData?.refunds?.last,
                    )
                  : const SizedBox.shrink(),
              OrderMap(
                isLoading: state.isMapLoading,
                polylineCoordinates: state.polylineCoordinates,
                markers: Set<Marker>.of(state.markers.values),
                latLng: LatLng(
                  state.orderData?.shop?.location?.latitude ?? 0,
                  state.orderData?.shop?.location?.longitude ?? 0,
                ),
              ),
              24.verticalSpace,
              TitleAndIcon(
                title: AppHelpers.getTranslation(TrKeys.compositionOrder),
              ),
              Consumer(
                builder: (context, ref, child) {
                  return ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount:
                        ref.watch(orderProvider).orderData?.details?.length ??
                            0,
                    itemBuilder: (context, index) {
                      return EmbeddedWidgets.I.cartOrderItem(
                        isAddComment: true,
                        symbol: state.orderData?.currencyModel?.symbol ?? "",
                        isActive: false,
                        add: () {},
                        remove: () {},
                        cartTwo:
                            ref.watch(orderProvider).orderData?.details?[index],
                        cart: null,
                      );
                    },
                  );
                },
              ),
              OrderCheck(
                orderStatus: AppHelpers.getOrderStatus(
                  state.orderData?.status ?? "",
                ),
                isOrder: true,
                isActive: state.isActive,
                globalKey: _scaffoldKey,
              ),
              42.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }

  CommonAppBar _appBar(BuildContext context, OrderState state) {
    return CommonAppBar(
      height: 170,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ShopAvatar(
                shopImage: state.orderData?.shop?.logoImg ?? "",
                size: 40,
                padding: 4,
                radius: 8,
                bgColor: AppStyle.black.withOpacity(0.06),
              ),
              10.horizontalSpace,
              SizedBox(
                width: MediaQuery.sizeOf(context).width - 98.w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      state.orderData?.shop?.translation?.title ?? "",
                      style: AppStyle.interSemi(
                        size: 16,
                        color: AppStyle.inkFor(Theme.of(context).brightness),
                      ),
                      maxLines: 1,
                    ),
                    Text(
                      state.orderData?.shop?.translation?.description ?? "",
                      style: AppStyle.interNormal(
                        size: 12,
                        color: AppStyle.inkFor(Theme.of(context).brightness),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          OrderStatusScreen(
            status: AppHelpers.getOrderStatus(state.orderData?.status ?? ""),
          ),
        ],
      ),
    );
  }
}
