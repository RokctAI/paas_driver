import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../../application/order/all_order/order_provider.dart';
import '../../../component/loading.dart';
import '../../../component/orders_item.dart';

class AllOrdersBody extends ConsumerStatefulWidget {
  final RefreshController refreshController;

  const AllOrdersBody({super.key, required this.refreshController});

  @override
  ConsumerState<AllOrdersBody> createState() => _AllOrdersBodyState();
}

class _AllOrdersBodyState extends ConsumerState<AllOrdersBody> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderProvider);
    return state.isLoading
        ? const Padding(padding: EdgeInsets.only(top: 32), child: Loading())
        : SmartRefresher(
            enablePullDown: true,
            enablePullUp: true,
            onRefresh: () {
              ref
                  .read(orderProvider.notifier)
                  .fetchHistoryOrdersPage(
                    context,
                    widget.refreshController,
                    isRefresh: true,
                  );
            },
            onLoading: () {
              ref
                  .read(orderProvider.notifier)
                  .fetchHistoryOrdersPage(context, widget.refreshController);
            },
            controller: widget.refreshController,
            child: ListView.builder(
              padding: EdgeInsets.only(
                top: 30.h,
                bottom: MediaQuery.paddingOf(context).bottom + 42.h,
              ),
              shrinkWrap: true,
              itemCount: state.historyOrders.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return OrdersItem(
                  isOrder: false,
                  order: state.historyOrders[index],
                );
              },
            ),
          );
  }
}
