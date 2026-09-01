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
