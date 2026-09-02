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
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'orders_board_state.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';
import 'package:orders_sdk/src/manager/presentation/board/board_status.dart';

/// Status transitions triggered from the wide-screen order board.
///
/// Same repository call the order-details modal's swipe button makes
/// ([SellerOrdersRepositoryFacade.updateOrderStatus]), but keyed by an
/// explicit [orderId] instead of the modal's fetched `state.order`, so a card
/// dragged between columns never has to open the details sheet first.
/// [OrdersBoardState.updatingIds] lets the board dim/lock a card while its
/// transition is in flight.
class OrdersBoardNotifier extends StateNotifier<OrdersBoardState> {
  final SellerOrdersRepositoryFacade _ordersRepository;

  OrdersBoardNotifier(this._ordersRepository) : super(const OrdersBoardState());

  /// [status] is the board's own seven-status axis; statuses base_sdk's
  /// `OrderStatus` models go through it, `cooking` goes by wire string.
  Future<void> updateOrderStatus(
    BuildContext context, {
    required String orderId,
    required BoardStatus status,
    VoidCallback? success,
  }) async {
    if (state.updatingIds.contains(orderId)) {
      return;
    }
    state = state.copyWith(updatingIds: {...state.updatingIds, orderId});
    final response = await _ordersRepository.updateOrderStatus(
      status: status.orderStatus,
      rawStatus: status.orderStatus == null ? status.wire : null,
      orderId: orderId,
    );
    response.when(
      success: (data) {
        state = state.copyWith(
          updatingIds: {...state.updatingIds}..remove(orderId),
        );
        success?.call();
      },
      failure: (failure, statusCode) {
        debugPrint('===> board update order status fail $failure');
        state = state.copyWith(
          updatingIds: {...state.updatingIds}..remove(orderId),
        );
        AppHelpers.showCheckTopSnackBar(context, failure);
      },
    );
  }
}
