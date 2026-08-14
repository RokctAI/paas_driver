import 'package:flutter/material.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'order_details_state.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';

class OrderDetailsNotifier extends StateNotifier<OrderDetailsState> {
  final SellerOrdersRepositoryFacade _ordersRepository;

  OrderDetailsNotifier(this._ordersRepository)
      : super(const OrderDetailsState());

  Future<void> updateOrderStatus(BuildContext context,{
    required OrderStatus status,
    VoidCallback? success,
  }) async {
    state = state.copyWith(isUpdating: true);
    final response = await _ordersRepository.updateOrderStatus(
      status: status,
      orderId: state.order?.id,
    );
    response.when(
      success: (data) {
        state = state.copyWith(isUpdating: false);
        success?.call();
      },
      failure: (failure,status) {
        debugPrint('===> update order status fail $failure');
        state = state.copyWith(isUpdating: false);
        AppHelpers.showCheckTopSnackBar(context, failure);
      },
    );
  }

  void toggleOrderDetailChecked({required int index}) {
    List<OrderDetail>? orderDetails = state.order?.details;
    if (orderDetails == null || orderDetails.isEmpty) {
      return;
    }
    OrderDetail detail = orderDetails[index];
    final bool isChecked = detail.isChecked ?? false;
    detail = detail.copyWith(isChecked: !isChecked);
    orderDetails[index] = detail;
    final order = state.order?.copyWith(details: orderDetails);
    state = state.copyWith(order: order);
  }

  Future<void> fetchOrderDetails({OrderData? order}) async {
    state = state.copyWith(isLoading: true, order: order);
    final response =
        await _ordersRepository.getOrderDetails(orderId: order?.id);
    response.when(
      success: (data) {
        state = state.copyWith(isLoading: false, order: data.data);
      },
      failure: (failure,status) {
        debugPrint('===> fetch order details fail $failure');
        state = state.copyWith(isLoading: false);
      },
    );
  }
}
