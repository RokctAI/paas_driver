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

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:orders_sdk/src/manager/application/orders/accepted/accepted_orders_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/canceled/canceled_orders_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/cooking/cooking_orders_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/delivered/delivered_orders_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/new/new_orders_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/on_a_way/on_a_way_orders_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/ready/ready_orders_provider.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

import 'board_card.dart';
import 'board_column.dart';
import 'board_prefs.dart';
import 'board_refresh.dart';
import 'board_status.dart';

/// The POS's LIST MODE, chosen as the phone shape per approved frame 33b:
/// the seven statuses as one scrollable row of colour-coded tabs with
/// their count pills; below, the selected status's orders as full-width
/// cards — same clock, same progress chip, same "View more · +N" paging.
/// A waiter login loses the On-the-way tab, same rule as the board.
class OrdersListMode extends ConsumerStatefulWidget {
  final void Function(OrderData order, BoardStatus status) onOpenDetail;
  final void Function(OrderData order)? onOpenMap;

  const OrdersListMode({super.key, required this.onOpenDetail, this.onOpenMap});

  @override
  ConsumerState<OrdersListMode> createState() => _OrdersListModeState();
}

class _OrdersListModeState extends ConsumerState<OrdersListMode> {
  String? get _role => LocalStorage.getUser()?.role;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // The home page fetches the four legacy queues; the list mode also
      // shows cooking + history, so fetch those here.
      fetchBoardColumn(ref, context, BoardStatus.cooking, isRefresh: true);
      fetchBoardColumn(ref, context, BoardStatus.delivered, isRefresh: true);
      fetchBoardColumn(ref, context, BoardStatus.canceled, isRefresh: true);
    });
  }

  ({List<OrderData> orders, int count, bool loading}) _stateOf(
    BoardStatus status,
  ) {
    switch (status) {
      case BoardStatus.newOrder:
        final s = ref.watch(newOrdersProvider);
        return (orders: s.orders, count: s.totalCount, loading: s.isLoading);
      case BoardStatus.accepted:
        final s = ref.watch(acceptedOrdersProvider);
        return (orders: s.orders, count: s.totalCount, loading: s.isLoading);
      case BoardStatus.cooking:
        final s = ref.watch(cookingOrdersProvider);
        return (orders: s.orders, count: s.totalCount, loading: s.isLoading);
      case BoardStatus.ready:
        final s = ref.watch(readyOrdersProvider);
        return (orders: s.orders, count: s.totalCount, loading: s.isLoading);
      case BoardStatus.onWay:
        final s = ref.watch(onAWayOrdersProvider);
        return (orders: s.orders, count: s.totalCount, loading: s.isLoading);
      case BoardStatus.delivered:
        final s = ref.watch(deliveredOrdersProvider);
        return (orders: s.orders, count: s.totalCount, loading: s.isLoading);
      case BoardStatus.canceled:
        final s = ref.watch(canceledOrdersProvider);
        return (orders: s.orders, count: s.totalCount, loading: s.isLoading);
    }
  }

  @override
  Widget build(BuildContext context) {
    final columns = BoardRules.columnsFor(role: _role);
    final prefs = ref.watch(boardPrefsProvider);
    final int activeIndex = math.min(prefs.listTabIndex, columns.length - 1);
    final BoardStatus active = columns[activeIndex];
    final activeState = _stateOf(active);
    final int moreCount = math.max(
      0,
      activeState.count - activeState.orders.length,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 44,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              for (var i = 0; i < columns.length; i++)
                _tabChip(columns[i], isActive: i == activeIndex, index: i),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: activeState.loading && activeState.orders.isEmpty
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : activeState.orders.isEmpty
              ? Center(
                  child: Text(
                    AppHelpers.getTranslation('no_orders'),
                    style: AppStyle.interNormal(
                      size: 12,
                      color: AppStyle.textDarkSecondary,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async =>
                      fetchBoardColumn(ref, context, active, isRefresh: true),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    children: [
                      for (final order in activeState.orders)
                        BoardOrderCard(
                          order: order,
                          status: active,
                          onTap: () => widget.onOpenDetail(order, active),
                          onMapTap: widget.onOpenMap == null
                              ? null
                              : () => widget.onOpenMap!.call(order),
                        ),
                      if (moreCount > 0)
                        InkWell(
                          onTap: () => fetchBoardColumn(
                            ref,
                            context,
                            active,
                            isRefresh: false,
                          ),
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            height: 34,
                            margin: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: AppStyle.strokeDark),
                            ),
                            child: Center(
                              child: Text(
                                '${AppHelpers.getTranslation('view_more')}  ·  +$moreCount',
                                style: AppStyle.interSemi(
                                  size: 11.5,
                                  color: AppStyle.textDarkSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _tabChip(
    BoardStatus status, {
    required bool isActive,
    required int index,
  }) {
    final s = _stateOf(status);
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: InkWell(
        onTap: () => ref.read(boardPrefsProvider.notifier).selectListTab(index),
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: isActive
                ? status.color.withValues(alpha: 0.16)
                : AppStyle.cardDark,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isActive ? status.color : AppStyle.strokeDark,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppHelpers.getTranslation(status.wire),
                style: isActive
                    ? AppStyle.interSemi(size: 12, color: AppStyle.textPrimary)
                    : AppStyle.interNormal(
                        size: 12,
                        color: AppStyle.textDarkSecondary,
                      ),
              ),
              const SizedBox(width: 7),
              BoardCountPill(status: status, count: s.count),
            ],
          ),
        ),
      ),
    );
  }
}
