import 'package:driver/application/order/canceled_order/canceled_order_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../component/loading.dart';
import '../../../component/orders_item.dart';

class CanceledOrdersBody extends ConsumerStatefulWidget {
  final RefreshController refreshController;

  const CanceledOrdersBody({super.key, required this.refreshController});

  @override
  ConsumerState<CanceledOrdersBody> createState() => _CanceledOrdersBody();
}

class _CanceledOrdersBody extends ConsumerState<CanceledOrdersBody> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(canceledOrderProvider);
    return state.isLoading
        ? const Padding(padding: EdgeInsets.only(top: 32), child: Loading())
        : SmartRefresher(
            enablePullDown: true,
            enablePullUp: true,
            onRefresh: () {
              ref
                  .read(canceledOrderProvider.notifier)
                  .fetchCanceledOrdersPage(
                    context,
                    widget.refreshController,
                    isRefresh: true,
                  );
            },
            onLoading: () {
              ref
                  .read(canceledOrderProvider.notifier)
                  .fetchCanceledOrdersPage(context, widget.refreshController);
            },
            controller: widget.refreshController,
            child: ListView.builder(
              padding: EdgeInsets.only(
                top: 30.h,
                bottom: MediaQuery.paddingOf(context).bottom + 42.h,
              ),
              shrinkWrap: true,
              itemCount: state.canceledOrders.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return OrdersItem(
                  isOrder: false,
                  order: state.canceledOrders[index],
                );
              },
            ),
          );
  }
}
