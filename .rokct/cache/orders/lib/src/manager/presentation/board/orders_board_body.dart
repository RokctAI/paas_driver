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

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:orders_sdk/src/manager/application/orders/accepted/accepted_orders_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/board/orders_board_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/canceled/canceled_orders_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/cooking/cooking_orders_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/delivered/delivered_orders_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/new/new_orders_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/on_a_way/on_a_way_orders_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/ready/ready_orders_provider.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

import 'board_column.dart';
import 'board_refresh.dart';
import 'board_status.dart';

/// The approved seven-column kanban board (frame 33a): New / Accepted /
/// Cooking / Ready / On the way / Delivered / Cancelled, colour-coded, each
/// with count pill, per-column refresh and "View more · +N" paging;
/// horizontal scroll carries the far columns past the right edge. Cards
/// long-press-drag forward along the state machine; the SMART SKIP routes a
/// pickup dropped on On the way into Delivered (with the approved airborne
/// treatment: On the way dims, Delivered lights its landing slot, a hint
/// banner spells it out). A waiter login hides the On-the-way column.
///
/// Detail opening is delegated to [onOpenDetail] — the template page owns
/// it (33d: plane push on wide windows, modal sheet on the phone).
class OrdersBoardBody extends ConsumerStatefulWidget {
  final void Function(OrderData order, BoardStatus status) onOpenDetail;
  final void Function(OrderData order)? onOpenMap;

  /// The order whose detail currently holds the last plane (33d) — its
  /// card keeps the brand border.
  final String? selectedOrderId;

  const OrdersBoardBody({
    super.key,
    required this.onOpenDetail,
    this.onOpenMap,
    this.selectedOrderId,
  });

  @override
  ConsumerState<OrdersBoardBody> createState() => _OrdersBoardBodyState();
}

class _OrdersBoardBodyState extends ConsumerState<OrdersBoardBody> {
  final ScrollController _boardController = ScrollController();
  final ValueNotifier<BoardDragData?> _drag = ValueNotifier(null);

  String? get _role => LocalStorage.getUser()?.role;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // The four active queues are fetched by OrdersHomePage; the board
      // additionally owns its cooking queue and the two history columns.
      _refreshColumn(BoardStatus.cooking);
      _refreshColumn(BoardStatus.delivered);
      _refreshColumn(BoardStatus.canceled);
    });
  }

  @override
  void dispose() {
    _boardController.dispose();
    _drag.dispose();
    super.dispose();
  }

  void _refreshColumn(BoardStatus status) =>
      fetchBoardColumn(ref, context, status, isRefresh: true);

  void _loadMoreColumn(BoardStatus status) =>
      fetchBoardColumn(ref, context, status, isRefresh: false);

  bool _canAccept(BoardStatus target, BoardDragData data) {
    if (data.order.id == null) return false;
    return BoardRules.canMove(from: data.from, to: target);
  }

  void _onAccept(BoardStatus target, BoardDragData data) {
    final String? orderId = data.order.id;
    if (orderId == null) return;
    // THE SMART SKIP (POS board_view.dart:266-273): a pickup dropped on
    // On the way lands in Delivered.
    final BoardStatus resolved = BoardRules.resolveDrop(
      target: target,
      deliveryType: data.order.deliveryType,
    );
    ref
        .read(ordersBoardProvider.notifier)
        .updateOrderStatus(
          context,
          orderId: orderId,
          status: resolved,
          success: () {
            _refreshColumn(data.from);
            _refreshColumn(resolved);
          },
        );
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
    final updatingIds = ref.watch(ordersBoardProvider).updatingIds;

    return ValueListenableBuilder<BoardDragData?>(
      valueListenable: _drag,
      builder: (context, drag, _) {
        // The approved airborne treatment: while a pickup is dragged from
        // before On the way, that column dims and Delivered shows the
        // landing slot.
        final bool skipActive =
            drag != null &&
            drag.skipsOnWay &&
            drag.from.index < BoardStatus.onWay.index;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (skipActive) _skipHint(),
            Expanded(
              child: Scrollbar(
                controller: _boardController,
                thumbVisibility: true,
                scrollbarOrientation: ScrollbarOrientation.bottom,
                child: SingleChildScrollView(
                  controller: _boardController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final status in columns)
                        _column(
                          status,
                          updatingIds: updatingIds,
                          dimmed: skipActive && status == BoardStatus.onWay,
                          showDropSlot:
                              skipActive && status == BoardStatus.delivered,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _skipHint() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: AppStyle.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppStyle.primary.withValues(alpha: 0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                FlutterRemix.share_forward_line,
                size: 15,
                color: AppStyle.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  AppHelpers.getTranslation('pickup_skips_on_a_way'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyle.interSemi(
                    size: 12,
                    color: AppStyle.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _column(
    BoardStatus status, {
    required Set<String> updatingIds,
    required bool dimmed,
    required bool showDropSlot,
  }) {
    final s = _stateOf(status);
    return BoardOrderColumn(
      status: status,
      title: AppHelpers.getTranslation(status.wire),
      count: s.count,
      isLoading: s.loading,
      orders: s.orders,
      moreCount: math.max(0, s.count - s.orders.length),
      updatingIds: updatingIds,
      dimmed: dimmed,
      showDropSlot: showDropSlot,
      onRefresh: () => _refreshColumn(status),
      onViewMore: () => _loadMoreColumn(status),
      onOrderTap: (order) => widget.onOpenDetail(order, status),
      onOrderMapTap: widget.onOpenMap,
      canAccept: (data) => _canAccept(status, data),
      onAccept: (data) => _onAccept(status, data),
      onDragChanged: (data) => _drag.value = data,
      selectedOrderId: widget.selectedOrderId,
    );
  }
}
