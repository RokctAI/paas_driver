// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
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

// ORDER HISTORY IN THE STANDARD LIST LANGUAGE — approved design strip
// frames 38a (tablet, three planes) and 38d (the phone fold), Ray
// 2026-08-30 12:23Z ("33 list language = STANDARD for all lists").
//
// The shipped page (templates/pages/manager/order_history/order_history.dart)
// was an undesigned white ListView with two floating buttons. Redressed:
//
//   700  the header COUNT PILL — the shipped "There are N orders" line
//        re-homed as the standard slot
//   358  the header DATE-RANGE FILTER — the shipped FilterScreen re-homed
//        from its equalizer FAB to a header round utility
//   362/363  the status TAB BAR — history's real statuses, the legacy
//        pair delivered + canceled, in the 33a colours (Delivered =
//        primary, Cancelled = red)
//   352/353/354  the ORDER CARD unit carried to a FINISHED order: the
//        board card with its progress chip full at 100% and its clock
//        FROZEN ("took 23m" + the final range — 33a's freeze rule,
//        extended to finished orders)
//   356  VIEW MORE · +N paging
//
// THE STATUSES, disclosed: the shipped `fetchHistoryOrders` call asks
// get_seller_orders for `delivered` only — the `statuses[]` filter is a
// recorded endpoint gap, so a single call cannot fill both tabs. The two
// tabs are therefore fed by the board's own per-status queues
// (deliveredOrdersProvider / canceledOrdersProvider), which already page
// and count each status separately against the same endpoint. Real
// counts, real paging, no new endpoint.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:base_sdk/src/presentation/components/lists/list_language.dart';
import 'package:base_sdk/src/presentation/components/lists/list_plane_flow.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:orders_sdk/src/manager/application/orders/canceled/canceled_orders_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/delivered/delivered_orders_provider.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

import '../board/board_card.dart';
import '../board/board_status.dart';

/// The two statuses history shows, in the legacy order the shipped
/// history call intended (`statuses[delivered, canceled]`).
const List<BoardStatus> kOrderHistoryStatuses = <BoardStatus>[
  BoardStatus.delivered,
  BoardStatus.canceled,
];

/// The order-history list body: header (700 + 358), status tabs
/// (362/363), the finished-order cards in plane-aligned columns, and the
/// View-more foot (356).
///
/// Self-contained: it owns its active tab and its date range, so opening
/// history never disturbs the orders board's own header state.
class OrderHistoryList extends ConsumerStatefulWidget {
  /// Tapping a card. On planes this pushes the detail PANE; on the phone
  /// the caller opens the shipped bottom sheet (38d).
  final void Function(OrderData order, BoardStatus status) onOpenDetail;

  /// The card whose detail currently holds the last plane (brand border).
  final String? selectedOrderId;

  /// Phone shape: one column, compact header metrics (38d).
  final bool compact;

  const OrderHistoryList({
    super.key,
    required this.onOpenDetail,
    this.selectedOrderId,
    this.compact = false,
  });

  @override
  ConsumerState<OrderHistoryList> createState() => OrderHistoryListState();
}

class OrderHistoryListState extends ConsumerState<OrderHistoryList> {
  int _activeIndex = 0;
  DateTime? _from;
  DateTime? _to;

  BoardStatus get activeStatus => kOrderHistoryStatuses[_activeIndex];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final status in kOrderHistoryStatuses) {
        _fetch(status, isRefresh: true);
      }
    });
  }

  String? get _fromWire =>
      _from == null ? null : DateFormat('yyyy-MM-dd').format(_from!);

  String? get _toWire =>
      _to == null ? null : DateFormat('yyyy-MM-dd').format(_to!);

  void _fetch(BoardStatus status, {required bool isRefresh}) {
    switch (status) {
      case BoardStatus.canceled:
        ref
            .read(canceledOrdersProvider.notifier)
            .fetchCanceledOrders(
              isRefresh: isRefresh,
              from: _fromWire,
              to: _toWire,
            );
        break;
      // Delivered is history's default; anything else the caller hands us
      // reads as the delivered queue rather than silently fetching
      // nothing.
      case BoardStatus.newOrder:
      case BoardStatus.accepted:
      case BoardStatus.cooking:
      case BoardStatus.ready:
      case BoardStatus.onWay:
      case BoardStatus.delivered:
        ref
            .read(deliveredOrdersProvider.notifier)
            .fetchDeliveredOrders(
              isRefresh: isRefresh,
              from: _fromWire,
              to: _toWire,
            );
        break;
    }
  }

  ({List<OrderData> orders, int count, bool loading}) _stateOf(
    BoardStatus status,
  ) {
    if (status == BoardStatus.canceled) {
      final s = ref.watch(canceledOrdersProvider);
      return (orders: s.orders, count: s.totalCount, loading: s.isLoading);
    }
    final s = ref.watch(deliveredOrdersProvider);
    return (orders: s.orders, count: s.totalCount, loading: s.isLoading);
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: _from == null || _to == null
          ? null
          : DateTimeRange(start: _from!, end: _to!),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _from = picked.start;
      _to = picked.end;
    });
    for (final status in kOrderHistoryStatuses) {
      _fetch(status, isRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = activeStatus;
    final activeState = _stateOf(active);
    // 700: the shipped "There are N orders" line, re-homed — history's
    // total is both tabs together, which is exactly what the shipped
    // header counted.
    final int totalCount = kOrderHistoryStatuses.fold(
      0,
      (sum, status) => sum + _stateOf(status).count,
    );
    final int moreCount = math.max(
      0,
      activeState.count - activeState.orders.length,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListScreenHeader(
          compact: widget.compact,
          title: AppHelpers.getTranslation('order_history'),
          countPill: ListCountPill(
            label:
                '$totalCount ${AppHelpers.getTranslation('orders').toLowerCase()}',
          ),
          actions: [
            ListRoundAction(
              icon: Icons.calendar_today_outlined,
              active: _from != null,
              tooltip: _from == null || _to == null
                  ? AppHelpers.getTranslation('start_end')
                  : '${DateFormat('d MMM').format(_from!)} – '
                        '${DateFormat('d MMM').format(_to!)}',
              onTap: _pickRange,
            ),
          ],
        ),
        ListFilterTabBar(
          activeIndex: _activeIndex,
          onSelect: (index) => setState(() => _activeIndex = index),
          tabs: [
            for (final status in kOrderHistoryStatuses)
              ListFilterTab(
                label: AppHelpers.getTranslation(status.wire),
                color: status.color,
                count: _stateOf(status).count,
                darkPillText: status.darkPillText,
              ),
          ],
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
                  onRefresh: () async => _fetch(active, isRefresh: true),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    children: [
                      ListPlaneColumns(
                        // 356: on the phone fold the View-more button
                        // stops short of the bottom-END corner so the
                        // back pill owns it (38d).
                        footer: ListViewMore(
                          moreCount: moreCount,
                          label: AppHelpers.getTranslation('view_more'),
                          margin: widget.compact
                              ? const EdgeInsetsDirectional.fromSTEB(
                                  6,
                                  0,
                                  84,
                                  8,
                                )
                              : const EdgeInsets.fromLTRB(6, 0, 6, 8),
                          onTap: () => _fetch(active, isRefresh: false),
                        ),
                        children: [
                          for (final order in activeState.orders)
                            BoardOrderCard(
                              order: order,
                              status: active,
                              selected:
                                  widget.selectedOrderId != null &&
                                  widget.selectedOrderId == order.id,
                              onTap: () => widget.onOpenDetail(order, active),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
