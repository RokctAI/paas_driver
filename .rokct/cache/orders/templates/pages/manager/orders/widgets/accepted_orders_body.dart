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
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'no_orders.dart';
import 'package:${package}/presentation/pages/orders/details/order_details_modal.dart';
import 'package:base_sdk/src/presentation/components/loading/loading_list.dart';
import 'package:${package}/presentation/components/orders/order_item.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:orders_sdk/src/manager/application/orders/accepted/accepted_orders_provider.dart';

class AcceptedOrdersBody extends StatefulWidget {
  final ScrollController? scrollController;

  const AcceptedOrdersBody({super.key, this.scrollController}) ;

  @override
  State<AcceptedOrdersBody> createState() => _AcceptedOrdersBodyState();
}

class _AcceptedOrdersBodyState extends State<AcceptedOrdersBody> {
  late RefreshController _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = RefreshController();
  }

  @override
  void dispose() {
    super.dispose();
    _refreshController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final event = ref.read(acceptedOrdersProvider.notifier);
        final state = ref.watch(acceptedOrdersProvider);
        return SmartRefresher(
          physics: const BouncingScrollPhysics(),
          controller: _refreshController,
          enablePullDown: true,
          enablePullUp: true,
          onLoading: () =>
              event.fetchAcceptedOrders(refreshController: _refreshController),
          onRefresh: () => event.fetchAcceptedOrders(
            refreshController: _refreshController,
            isRefresh: true,
          ),
          child: state.isLoading
              ? const LoadingList(
                  horizontalPadding: 16,
                  verticalPadding: 16,
                )
              : state.orders.isNotEmpty
                  ? ListView.builder(
                      padding: REdgeInsets.only(
                          right: 16, left: 16, top: 16, bottom: 100),
                      shrinkWrap: true,
                      itemCount: state.orders.length,
                      controller: widget.scrollController,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) => OrderItem(
                        order: state.orders[index],
                        onTap: () => AppHelpers.showCustomModalBottomSheet(
                          paddingTop: MediaQuery.paddingOf(context).top + 60,
                          context: context,
                          radius: 12,
                          modal: OrderDetailsModal(
                            order: state.orders[index],
                            acceptedOrdersController: _refreshController,
                          ),
                          isDarkMode: true,
                        ),
                      ),
                    )
                  : const NoOrders(),
        );
      },
    );
  }
}
