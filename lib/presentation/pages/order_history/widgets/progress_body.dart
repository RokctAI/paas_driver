import 'package:driver/application/order/progress_ordedr/progress_order_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../../application/order/all_order/order_provider.dart';
import '../../../component/loading.dart';
import '../../../component/orders_item.dart';

class ProgressOrdersBody extends ConsumerStatefulWidget {
  final RefreshController refreshController;

  const ProgressOrdersBody({super.key, required this.refreshController});

  @override
  ConsumerState<ProgressOrdersBody> createState() => _ProgressOrdersBody();
}

class _ProgressOrdersBody extends ConsumerState<ProgressOrdersBody> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(progressOrderProvider);
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
              itemCount: state.progressOrders.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return OrdersItem(
                  isOrder: false,
                  order: state.progressOrders[index],
                );
              },
            ),
          );
  }
}
