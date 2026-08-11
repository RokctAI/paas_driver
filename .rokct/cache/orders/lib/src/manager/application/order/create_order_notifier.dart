import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'create_order_state.dart';
import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

class CreateOrderNotifier extends StateNotifier<CreateOrderState> {
  final SellerOrdersRepositoryFacade _ordersRepository;

  CreateOrderNotifier(this._ordersRepository,)
      : super(const CreateOrderState());

  Future<void> createOrder({
    required String deliveryType,
    UserData? user,
    required List<Stock> stocks,
    required String deliveryDate,
    required String address,
    required int? tableId,
    LocationModel? location,
    required String entrance,
    required String floor,
    required String house,
    int? paymentId,
    ValueChanged<int>? orderSuccess,
    ValueChanged<String>? orderQueued,
    Function(String)? failed,
  }) async {

    state = state.copyWith(isCreating: true);
    final response = await _ordersRepository.createOrder(
      deliveryType: deliveryType,
      user: user,
      stocks: stocks,
      deliveryTime: deliveryDate,
      address: address,
      location: location,
      tableId: tableId,
      entrance: entrance.isEmpty ? null : entrance.trim(),
      house: house.isEmpty ? null : house.trim(),
      floor: floor.isEmpty ? null : floor.trim(),
      paymentId: paymentId,
    );
    response.when(
      success: (data) async {
        state = state.copyWith(isCreating: false);
        if (data.localId != null && data.data?.id == null) {
          // Queued locally (backend unreachable): the sale is recorded under
          // its offline: id and the sync handler will create order +
          // transaction later, so the POS must not call createTransaction.
          orderQueued?.call(data.localId!);
        } else {
          orderSuccess?.call(data.data?.id ?? 0);
        }
      },
      failure: (failure,status) {
        debugPrint('===> create order fail $failure');
        failed?.call(failure.toString());
        state = state.copyWith(isCreating: false);
      },
    );
  }
}
