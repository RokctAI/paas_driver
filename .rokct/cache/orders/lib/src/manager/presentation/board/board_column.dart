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
import 'package:flutter_remix/flutter_remix.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

import 'board_card.dart';
import 'board_status.dart';

/// Payload carried while an order card is dragged between board columns:
/// the order plus the column it left, so drop targets can decide whether
/// the move is a legal forward transition — and whether the SMART SKIP
/// applies (a pickup dropped on On the way lands in Delivered).
class BoardDragData {
  final OrderData order;
  final BoardStatus from;

  const BoardDragData({required this.order, required this.from});

  /// True when this order never travels with a driver (neither dine-in nor
  /// delivery — i.e. a pickup): the drag that triggers the smart skip.
  bool get skipsOnWay =>
      BoardRules.resolveDrop(
        target: BoardStatus.onWay,
        deliveryType: order.deliveryType,
      ) !=
      BoardStatus.onWay;
}

/// One status column of the approved board (frame 33a): colour-coded
/// header with count pill and per-column refresh, the card stack,
/// "View more · +N" paging, and the drag-target behaviour including the
/// smart-skip treatment (frame 33d's sibling 33-drag frame): while a
/// pickup card is airborne the On-the-way column [dimmed]s out and the
/// Delivered column shows its "drop here" landing slot.
class BoardOrderColumn extends StatelessWidget {
  /// Column width in logical pixels — the POS's own 235 (plain logical
  /// pixels, not ScreenUtil units, for the same reason base_sdk's
  /// `windowSizeOf` uses them: on a desktop window the phone design-size
  /// scale would balloon them).
  static const double width = 235;

  final BoardStatus status;
  final String title;
  final int count;
  final bool isLoading;
  final List<OrderData> orders;

  /// How many more orders the backend holds beyond the loaded page —
  /// drives "View more · +N".
  final int moreCount;

  /// Ids of orders whose status change is in flight — their cards are
  /// dimmed and locked.
  final Set<String> updatingIds;

  /// While a drag is airborne this column may be dimmed (the smart skip
  /// telling the user On the way is not where a pickup lands) …
  final bool dimmed;

  /// … and the Delivered column shows the lit landing slot instead.
  final bool showDropSlot;

  final VoidCallback onRefresh;
  final VoidCallback onViewMore;
  final void Function(OrderData order) onOrderTap;
  final void Function(OrderData order)? onOrderMapTap;
  final bool Function(BoardDragData data) canAccept;
  final void Function(BoardDragData data) onAccept;
  final ValueChanged<BoardDragData?>? onDragChanged;

  /// The card the user has opened in the detail plane (33d) — kept
  /// brand-bordered while its detail holds the last plane.
  final String? selectedOrderId;

  const BoardOrderColumn({
    super.key,
    required this.status,
    required this.title,
    required this.count,
    required this.isLoading,
    required this.orders,
    required this.moreCount,
    required this.updatingIds,
    required this.onRefresh,
    required this.onViewMore,
    required this.onOrderTap,
    required this.canAccept,
    required this.onAccept,
    this.onOrderMapTap,
    this.onDragChanged,
    this.dimmed = false,
    this.showDropSlot = false,
    this.selectedOrderId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: BoardOrderColumn.width,
      margin: const EdgeInsetsDirectional.only(end: 12),
      decoration: BoxDecoration(
        color: AppStyle.cardDarkAlt.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dimmed ? AppStyle.strokeDark : AppStyle.strokeDarkSubtle,
        ),
      ),
      child: Opacity(
        opacity: dimmed ? 0.45 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(),
            Expanded(
              child: DragTarget<BoardDragData>(
                onWillAcceptWithDetails: (details) => canAccept(details.data),
                onAcceptWithDetails: (details) => onAccept(details.data),
                builder: (context, candidates, rejected) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: candidates.isNotEmpty
                          ? status.color
                          : AppStyle.transparent,
                      width: 2,
                    ),
                  ),
                  child: isLoading && orders.isEmpty
                      ? const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : orders.isEmpty && !showDropSlot
                      ? _empty()
                      : _list(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      height: 40,
      margin: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppStyle.strokeDarkSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyle.interSemi(
                size: 12.5,
                color: AppStyle.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          BoardCountPill(status: status, count: count),
          const SizedBox(width: 4),
          InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: onRefresh,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      FlutterRemix.refresh_line,
                      size: 16,
                      color: AppStyle.textDarkSecondary,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          // 'no_orders' is a manifest-declared key; lib/ references it by
          // wire string (see manifest _comment_tr_keys precedent).
          AppHelpers.getTranslation('no_orders'),
          textAlign: TextAlign.center,
          style: AppStyle.interNormal(
            size: 12,
            color: AppStyle.textDarkSecondary,
          ),
        ),
      ),
    );
  }

  Widget _list() {
    return ListView(
      padding: const EdgeInsets.only(top: 2, bottom: 8),
      physics: const BouncingScrollPhysics(),
      children: [
        if (showDropSlot) _dropSlot(),
        for (final order in orders) _card(order),
        if (moreCount > 0) _viewMore(),
      ],
    );
  }

  /// The lit landing slot the smart skip points at (approved drag frame).
  Widget _dropSlot() {
    return Container(
      height: 64,
      margin: const EdgeInsets.fromLTRB(6, 0, 6, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppStyle.primary.withValues(alpha: 0.8),
          width: 1.4,
        ),
        color: AppStyle.primary.withValues(alpha: 0.08),
      ),
      child: Center(
        child: Text(
          AppHelpers.getTranslation('drop_here'),
          style: AppStyle.interSemi(size: 11.5, color: AppStyle.primary),
        ),
      ),
    );
  }

  Widget _viewMore() {
    return InkWell(
      onTap: onViewMore,
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
    );
  }

  Widget _card(OrderData order) {
    final card = BoardOrderCard(
      order: order,
      status: status,
      selected: selectedOrderId != null && order.id == selectedOrderId,
      onTap: () => onOrderTap(order),
      onMapTap: onOrderMapTap == null ? null : () => onOrderMapTap!.call(order),
    );
    final bool isUpdating = updatingIds.contains(order.id);
    if (isUpdating) {
      // In-flight cards are dimmed and locked.
      return IgnorePointer(child: Opacity(opacity: 0.5, child: card));
    }
    if (status == BoardStatus.canceled) {
      // Cancelled is terminal — nothing to drag it to.
      return card;
    }
    final data = BoardDragData(order: order, from: status);
    return LongPressDraggable<BoardDragData>(
      data: data,
      maxSimultaneousDrags: 1,
      onDragStarted: () => onDragChanged?.call(data),
      onDragEnd: (_) => onDragChanged?.call(null),
      onDraggableCanceled: (_, __) => onDragChanged?.call(null),
      feedback: Material(
        color: AppStyle.transparent,
        child: SizedBox(
          // Feedback floats in the overlay, outside this column's box
          // constraints, so it needs the width the card would have had —
          // and the POS lift treatment (tilt + shadow + brand border).
          width: BoardOrderColumn.width - 4,
          child: BoardOrderCard(order: order, status: status, lifted: true),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: card,
    );
  }
}

/// The coloured count pill (approved column header + phone status tabs).
class BoardCountPill extends StatelessWidget {
  final BoardStatus status;
  final int count;

  const BoardCountPill({super.key, required this.status, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: status.color,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        '$count',
        style: AppStyle.interBold(
          size: 11.5,
          color: status.darkPillText
              ? const Color(0xFF161616)
              : const Color(0xFFFFFFFF),
        ),
      ),
    );
  }
}
