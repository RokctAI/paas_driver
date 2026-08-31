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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:${package}/presentation/pages/orders/details/order_details_modal.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';
import 'package:orders_sdk/src/manager/presentation/board/board_map_dialog.dart';
import 'package:orders_sdk/src/manager/presentation/board/board_status.dart';
import 'package:orders_sdk/src/manager/presentation/board/orders_board_body.dart';

/// The approved seven-column kanban board (frame 33a — Ray 13:06Z "33a is
/// approved"). The board itself — columns, cards, clocks, drag machinery,
/// smart skip, waiter rule — lives in orders_sdk
/// (`presentation/board/orders_board_body.dart`) where it is analyzed and
/// tested; this template wrapper owns only what needs host paths: opening
/// the order details (the plane push comes from OrdersHomePage per 33d;
/// without it, the phone's modal sheet) and the delivery map dialog.
class OrdersBoardView extends ConsumerWidget {
  /// 33d wiring: when the home page hosts the board in a plane flow, taps
  /// push the detail into the LAST plane. Null falls back to the modal
  /// bottom sheet (the phone behaviour).
  final void Function(OrderData order, BoardStatus status)? onOpenDetail;

  /// The order whose detail holds the last plane — its card keeps the
  /// brand border.
  final String? selectedOrderId;

  const OrdersBoardView({super.key, this.onOpenDetail, this.selectedOrderId});

  void _openModal(BuildContext context, OrderData order, BoardStatus status) {
    AppHelpers.showCustomModalBottomSheet(
      paddingTop: MediaQuery.paddingOf(context).top + 60,
      context: context,
      radius: 12,
      modal: OrderDetailsModal(
        order: order,
        isHistoryOrder: status.isHistory ? true : null,
      ),
      isDarkMode: true,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OrdersBoardBody(
      onOpenDetail: (order, status) => onOpenDetail == null
          ? _openModal(context, order, status)
          : onOpenDetail!.call(order, status),
      onOpenMap: (order) => BoardMapDialog.show(context, order),
      selectedOrderId: selectedOrderId,
    );
  }
}
