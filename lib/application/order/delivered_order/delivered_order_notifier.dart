import 'package:driver/application/order/delivered_order/delivered_order_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../domain/di/dependency_manager.dart';
import '../../../infrastructure/models/data/order_detail.dart';
import '../../../infrastructure/services/app_connectivity.dart';
import '../../../infrastructure/services/app_helpers.dart';

class DeliveredOrderNotifier extends StateNotifier<DeliveredOrderState> {
  DeliveredOrderNotifier() : super(const DeliveredOrderState());

  int deliveredOrder = 0;

  Future<void> fetchDeliveredOrdersPage(
    BuildContext context,
    RefreshController controller, {
    bool isRefresh = false,
  }) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      if (isRefresh) {
        deliveredOrder = 1;
        state = state.copyWith(isLoading: true);
      }
      final response = await orderRepository.getHistoryOrders(
        isRefresh ? 1 : ++deliveredOrder,
        status: ["delivered"],
      );
      response.when(
        success: (data) {
          if (isRefresh) {
            state = state.copyWith(deliveredOrders: data, isLoading: false);
            controller.refreshCompleted();
          } else {
            if (data.isNotEmpty) {
              List<OrderDetailData> list = List.from(state.deliveredOrders);
              list.addAll(data);
              state = state.copyWith(deliveredOrders: list, isLoading: false);
              controller.loadComplete();
            } else {
              deliveredOrder--;
              controller.loadNoData();
            }
          }
        },
        failure: (failure, status) {
          if (!isRefresh) {
            deliveredOrder--;
            controller.loadFailed();
            state = state.copyWith(isLoading: false);
          } else {
            state = state.copyWith(isLoading: false);
            controller.refreshFailed();
          }
          AppHelpers.showCheckTopSnackBar(
            context,
            AppHelpers.getTranslation(failure),
          );
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
      state = state.copyWith(isLoading: false);
    }
  }
}
