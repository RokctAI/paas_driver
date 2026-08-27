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
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'orders_board_state.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';

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

  Future<void> updateOrderStatus(
    BuildContext context, {
    required String orderId,
    required OrderStatus status,
    VoidCallback? success,
  }) async {
    if (state.updatingIds.contains(orderId)) {
      return;
    }
    state = state.copyWith(updatingIds: {...state.updatingIds, orderId});
    final response = await _ordersRepository.updateOrderStatus(
      status: status,
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
