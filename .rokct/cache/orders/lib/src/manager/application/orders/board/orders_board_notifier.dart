import 'package:flutter/material.dart';
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
    required int orderId,
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
