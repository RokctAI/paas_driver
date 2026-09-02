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
    required String? tableId,
    LocationModel? location,
    required String entrance,
    required String floor,
    required String house,
    String? paymentId,
    ValueChanged<String>? orderSuccess,
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
          // The backend serves the Order docname (a hash string); never
          // substitute a sentinel — a missing id means nothing downstream
          // (navigation, transaction create) can act on the order.
          final String? orderId = data.data?.id;
          if (orderId == null) {
            debugPrint(
                '===> create order succeeded but returned no id; skipping '
                'success callback');
            return;
          }
          orderSuccess?.call(orderId);
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
