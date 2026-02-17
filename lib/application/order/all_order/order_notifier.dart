import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:driver/domain/interface/orders.dart';
import 'package:driver/infrastructure/models/data/order_detail.dart';
import 'package:driver/infrastructure/services/app_connectivity.dart';
import 'package:driver/infrastructure/services/app_helpers.dart';

import 'order_state.dart';

class OrderNotifier extends StateNotifier<OrderState> {
  final OrdersRepositoryFacade _orderRepository;

  OrderNotifier(this._orderRepository) : super(const OrderState());
  int activeOrder = 1;
  int historyOrder = 0;
  int availableOrderPage = 1;
  int deliveredOrder = 0;
  int canceledOrder = 0;

  void changeDeliveryType(int index) {
    state = state.copyWith(deliveryType: index);
  }

  void changeDeliveryTime(int index) {
    state = state.copyWith(deliveryTime: index);
  }

  void changePaymentType(bool isActive) {
    state = state.copyWith(paymentType: isActive);
  }

  Future<void> showOrder(BuildContext context, int orderId) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      state = state.copyWith(isLoading: true);
      final response = await _orderRepository.showOrders(orderId);
      response.when(
        success: (data) {
          state = state.copyWith(order: data.data, isLoading: false);
        },
        failure: (failure, status) {
          state = state.copyWith(isLoading: false);
          AppHelpers.showCheckTopSnackBar(
            context,
            AppHelpers.getTranslation(failure),
          );
          debugPrint('==> get order failure: $failure');
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future<void> setCurrentOrder(
    BuildContext context,
    int orderId,
    VoidCallback onSuccess,
  ) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      List<OrderDetailData> list = List.from(state.activeOrders);
      List<OrderDetailData> newList = list.map((element) {
        if (element.id == orderId) {
          element.current = true;
        } else {
          element.current = false;
        }
        return element;
      }).toList();
      state = state.copyWith(activeOrders: newList);
      final response = await _orderRepository.setCurrentOrder(orderId);

      response.when(
        success: (data) {
          onSuccess();
        },
        failure: (failure, status) {
          AppHelpers.showCheckTopSnackBar(
            context,
            AppHelpers.getTranslation(failure),
          );
          debugPrint('==> get set current order failure: $failure');
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future<void> fetchActiveOrders(BuildContext context) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      state = state.copyWith(isActiveLoading: true, activeOrders: []);
      final response = await _orderRepository.getActiveOrders(1);
      response.when(
        success: (data) {
          state = state.copyWith(
            activeOrders: data.data ?? [],
            totalActiveOrder: data.meta?.total ?? 0,
            isActiveLoading: false,
          );
        },
        failure: (failure, status) {
          state = state.copyWith(isActiveLoading: false);
          AppHelpers.showCheckTopSnackBar(
            context,
            AppHelpers.getTranslation(failure),
          );
          debugPrint('==> get active orders failure: $failure');
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future<void> fetchAvailableOrders(BuildContext context) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      state = state.copyWith(availableOrders: [], isAvailableLoading: true);
      final response = await _orderRepository.getAvailableOrders(1);
      response.when(
        success: (data) {
          state = state.copyWith(
            availableOrders: data,
            isAvailableLoading: false,
          );
        },
        failure: (failure, status) {
          state = state.copyWith(isAvailableLoading: true);
          AppHelpers.showCheckTopSnackBar(
            context,
            AppHelpers.getTranslation(failure),
          );
          debugPrint('==> get history orders failure: $failure');
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future<void> fetchActiveOrdersPage(
    BuildContext context,
    RefreshController controller, {
    bool isRefresh = false,
  }) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      if (isRefresh) {
        activeOrder = 1;
      }
      final response = await _orderRepository.getActiveOrders(
        isRefresh ? 1 : ++activeOrder,
      );
      response.when(
        success: (data) {
          if (isRefresh) {
            state = state.copyWith(
              activeOrders: data.data ?? [],
              totalActiveOrder: data.meta?.total ?? 0,
            );
            controller.refreshCompleted();
          } else {
            if (data.data?.isNotEmpty ?? false) {
              List<OrderDetailData> list = List.from(state.activeOrders);
              list.addAll(data.data ?? []);
              state = state.copyWith(activeOrders: list);
              controller.loadComplete();
            } else {
              activeOrder--;
              controller.loadNoData();
            }
          }
        },
        failure: (failure, status) {
          if (!isRefresh) {
            activeOrder--;
            controller.loadFailed();
          } else {
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
    }
  }

  Future<void> fetchAvailableOrdersPage(
    BuildContext context,
    RefreshController controller, {
    bool isRefresh = false,
  }) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      if (isRefresh) {
        availableOrderPage = 1;
      }
      final response = await _orderRepository.getAvailableOrders(
        isRefresh ? 1 : ++availableOrderPage,
      );
      response.when(
        success: (data) {
          if (isRefresh) {
            state = state.copyWith(availableOrders: data);
            controller.refreshCompleted();
          } else {
            if (data.isNotEmpty) {
              List<OrderDetailData> list = List.from(state.availableOrders);
              list.addAll(data);
              state = state.copyWith(availableOrders: list);
              controller.loadComplete();
            } else {
              availableOrderPage--;
              controller.loadNoData();
            }
          }
        },
        failure: (failure, status) {
          if (!isRefresh) {
            availableOrderPage--;
            controller.loadFailed();
          } else {
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
    }
  }

  Future<void> fetchHistoryOrders(
    BuildContext context, {
    DateTime? start,
    DateTime? end,
  }) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      state = state.copyWith(historyOrders: [], isHistoryLoading: true);
      final response = await _orderRepository.getHistoryOrders(
        1,
        start: start,
        end: end,
      );
      response.when(
        success: (data) {
          state = state.copyWith(historyOrders: data, isHistoryLoading: false);
        },
        failure: (failure, status) {
          state = state.copyWith(isHistoryLoading: true);
          AppHelpers.showCheckTopSnackBar(
            context,
            AppHelpers.getTranslation(failure),
          );
          debugPrint('==> get history orders failure: $failure');
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future<void> fetchHistoryOrdersPage(
    BuildContext context,
    RefreshController controller, {
    bool isRefresh = false,
  }) async {
    final connected = await AppConnectivity.connectivity();

    if (connected) {
      if (isRefresh) {
        historyOrder = 1;
        state = state.copyWith(isLoading: true);
      }
      final response = await _orderRepository.getHistoryOrders(
        isRefresh ? 1 : ++historyOrder,
        status: null,
      );
      response.when(
        success: (data) {
          if (isRefresh) {
            state = state.copyWith(historyOrders: data, isLoading: false);
            controller.refreshCompleted();
          } else {
            if (data.isNotEmpty) {
              List<OrderDetailData> list = List.from(state.historyOrders);
              list.addAll(data);
              state = state.copyWith(historyOrders: list, isLoading: false);
              controller.loadComplete();
            } else {
              historyOrder--;
              state = state.copyWith(isLoading: false);
              controller.loadNoData();
            }
          }
        },
        failure: (failure, status) {
          if (!isRefresh) {
            historyOrder--;
            state = state.copyWith(isLoading: false);
            controller.loadFailed();
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

  // Future<void> fetchDeliveredOrdersPage(
  //     BuildContext context, RefreshController controller,
  //     {bool isRefresh = false}) async {
  //   final connected = await AppConnectivity.connectivity();
  //   state=state.copyWith(isLoading: true);
  //   if (connected) {
  //     if (isRefresh) {
  //       deliveredOrder = 1;
  //     }
  //     final response =
  //     await _orderRepository.getHistoryOrders(isRefresh ? 1 : ++deliveredOrder, status:["delivered"]);
  //     response.when(
  //       success: (data) {
  //         if (isRefresh) {
  //           state = state.copyWith(
  //             deliveryOrders: data,
  //             isLoading: false,
  //           );
  //           controller.refreshCompleted();
  //         } else {
  //           if (data.isNotEmpty) {
  //             List<OrderDetailData> list = List.from(state.deliveryOrders);
  //             list.addAll(data);
  //             state = state.copyWith(
  //               deliveryOrders: list ,
  //               isLoading: false,
  //             );
  //             controller.loadComplete();
  //           } else {
  //              deliveredOrder --;
  //             controller.loadNoData();
  //           }
  //         }
  //
  //       },
  //       failure: (failure, status) {
  //         if (!isRefresh) {
  //           deliveredOrder--;
  //           state=state.copyWith(isLoading: false);
  //           controller.loadFailed();
  //         } else {
  //           state=state.copyWith(isLoading: false);
  //           controller.refreshFailed();
  //         }
  //         AppHelpers.showCheckTopSnackBar(
  //           context,
  //           AppHelpers.getTranslation(failure),
  //         );
  //       },
  //     );
  //   } else {
  //     if (context.mounted) {
  //       state=state.copyWith(isLoading: false);
  //       AppHelpers.showNoConnectionSnackBar(context);
  //     }
  //   }
  // }
  //
  // Future<void> fetchCanceledOrdersPage(
  //     BuildContext context, RefreshController controller,
  //     {bool isRefresh = false}) async {
  //   final connected = await AppConnectivity.connectivity();
  //   if (connected) {
  //     if (isRefresh) {
  //       canceledOrder = 1;
  //     }
  //     final response =
  //     await _orderRepository.getHistoryOrders(isRefresh ? 1 : ++canceledOrder, status:["canceled"]);
  //     response.when(
  //       success: (data) {
  //         if (isRefresh) {
  //           state = state.copyWith(
  //             cancelOrders: data,
  //           );
  //           controller.refreshCompleted();
  //         } else {
  //           if (data.isNotEmpty) {
  //             List<OrderDetailData> list = List.from(state.cancelOrders);
  //             list.addAll(data);
  //             state = state.copyWith(
  //               cancelOrders: list ,
  //             );
  //             controller.loadComplete();
  //           } else {
  //             canceledOrder --;
  //             controller.loadNoData();
  //           }
  //         }
  //
  //       },
  //       failure: (failure, status) {
  //         if (!isRefresh) {
  //           canceledOrder--;
  //           controller.loadFailed();
  //         } else {
  //           controller.refreshFailed();
  //         }
  //         AppHelpers.showCheckTopSnackBar(
  //           context,
  //           AppHelpers.getTranslation(failure),
  //         );
  //       },
  //     );
  //   } else {
  //     if (context.mounted) {
  //       AppHelpers.showNoConnectionSnackBar(context);
  //     }
  //   }
  // }
}
