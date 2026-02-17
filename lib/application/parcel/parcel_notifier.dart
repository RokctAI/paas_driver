import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:driver/domain/interface/parcel.dart';
import 'package:driver/infrastructure/models/data/parcel_order.dart';
import 'package:driver/infrastructure/services/app_connectivity.dart';
import 'package:driver/infrastructure/services/app_helpers.dart';

import 'parcel_state.dart';

class ParcelNotifier extends StateNotifier<ParcelState> {
  final ParcelRepositoryFacade _parcelRepo;

  ParcelNotifier(this._parcelRepo) : super(const ParcelState());
  int activeOrder = 1;
  int historyOrder = 1;
  int availableOrderPage = 1;

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
      final response = await _parcelRepo.showParcel(orderId);
      response.when(
        success: (data) {
          state = state.copyWith(order: data, isLoading: false);
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

  // Future<void> setCurrentOrder(BuildContext context,int orderId,VoidCallback onSuccess) async {
  //   final connected = await AppConnectivity.connectivity();
  //   if (connected) {
  //     List<OrderDetailData> list =  List.from(state.activeOrders);
  //     List<OrderDetailData> newList = list.map((element) {
  //       if(element.id == orderId){
  //         element.current = true;
  //       }else{
  //         element.current = false;
  //       }
  //       return element;
  //     }).toList();
  //     state = state.copyWith(activeOrders: newList);
  //     final response = await _orderRepository.setCurrentOrder(orderId);
  //
  //     response.when(
  //       success: (data) {
  //         onSuccess();
  //       },
  //       failure: (failure, status) {
  //
  //         AppHelpers.showCheckTopSnackBar(
  //           context,
  //           AppHelpers.getTranslation(failure),
  //         );
  //         debugPrint('==> get set current order failure: $failure');
  //       },
  //     );
  //   } else {
  //     if (context.mounted) {
  //       AppHelpers.showNoConnectionSnackBar(context);
  //     }
  //   }
  // }

  Future<void> fetchActiveOrders(BuildContext context) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      state = state.copyWith(isActiveLoading: true, activeOrders: []);
      final response = await _parcelRepo.getActiveOrders(1);
      response.when(
        success: (data) {
          state = state.copyWith(activeOrders: data, isActiveLoading: false);
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
      final response = await _parcelRepo.getAvailableOrders(1);
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
      final response = await _parcelRepo.getActiveOrders(
        isRefresh ? 1 : ++activeOrder,
      );
      response.when(
        success: (data) {
          if (isRefresh) {
            state = state.copyWith(activeOrders: data);
            controller.refreshCompleted();
          } else {
            if (data.isNotEmpty) {
              List<ParcelOrder> list = List.from(state.activeOrders);
              list.addAll(data);
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
      final response = await _parcelRepo.getAvailableOrders(
        isRefresh ? 1 : ++availableOrderPage,
      );
      response.when(
        success: (data) {
          if (isRefresh) {
            state = state.copyWith(availableOrders: data);
            controller.refreshCompleted();
          } else {
            if (data.isNotEmpty) {
              List<ParcelOrder> list = List.from(state.availableOrders);
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
      final response = await _parcelRepo.getHistoryOrders(
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
      }
      final response = await _parcelRepo.getHistoryOrders(
        isRefresh ? 1 : ++historyOrder,
      );
      response.when(
        success: (data) {
          if (isRefresh) {
            state = state.copyWith(historyOrders: data);
            controller.refreshCompleted();
          } else {
            if (data.isNotEmpty) {
              List<ParcelOrder> list = List.from(state.historyOrders);
              list.addAll(data);
              state = state.copyWith(historyOrders: list);
              controller.loadComplete();
            } else {
              historyOrder--;
              controller.loadNoData();
            }
          }
        },
        failure: (failure, status) {
          if (!isRefresh) {
            historyOrder--;
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
}
