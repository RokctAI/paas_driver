// Copyright (c) 2026 RokctAI
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

import 'dart:async';
import 'package:base_sdk/src/handlers/api_result.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'order_payment_state.dart';
import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

class OrderPaymentNotifier extends StateNotifier<OrderPaymentState> {
  final SellerOrdersRepositoryFacade _ordersRepository;

  OrderPaymentNotifier(this._ordersRepository)
      : super(const OrderPaymentState());

  void setSelectedIndex(int index) {
    state = state.copyWith(selectedIndex: index);
  }

  void clearSelectedPaymentInfo() {
    state = state.copyWith(selectedIndex: 0);
  }

  void setSelectedPayment(int index) {
    state = state.copyWith(selectedIndex: index);
  }

  void clearAll() {
    state = state.copyWith(orderCalculate: null);
  }

  Future<void> fetchPayments(String type) async {
    state = state.copyWith(isLoading: true);
    final response = await _ordersRepository.getPayments();
    response.when(
      success: (data) {
        final List<Payment> payments = data.data ?? [];
        List<Payment> filtered = [];
        for (final payment in payments) {
          if (type != TrKeys.delivery &&
              payment.payment?.tag?.toLowerCase() == 'cash') {
            filtered.add(payment);
            break;
          } else {
            if (payment.payment?.tag?.toLowerCase() == 'wallet' ||
                payment.payment?.tag?.toLowerCase() == 'cash') {
              filtered.add(payment);
            }
          }
        }
        state = state.copyWith(
          payments: filtered,
          selectedIndex: 0,
          isLoading: false,
        );
      },
      failure: (error, status) {
        debugPrint('====> fetch payments fail $error');
        state = state.copyWith(isLoading: false);
      },
    );
  }

  Future<void> createTransaction(
      BuildContext context, int orderId, int? paymentId) async {
    var response = await _ordersRepository.createTransaction(
        orderId: orderId, paymentId: paymentId ?? 0);
    response.when(
      success: (data) {},
      failure: (error, status) {
        debugPrint('====> fetch payments fail $error');
        AppHelpers.showCheckTopSnackBar(context, error);
      },
    );
  }

  Future<void> getCalculate({
    required List<Stock> stocks,
    required String type,
    LocationModel? location,
  }) async {
    state = state.copyWith(isCalculateLoading: true);
    final response = await _ordersRepository.getCalculate(
      stocks: stocks,
      type: type,
      location: location,
    );
    response.when(
      success: (data) {
        state = state.copyWith(
          orderCalculate: data.data,
          isCalculateLoading: false,
        );
      },
      failure: (error, status) {
        debugPrint('====> get calculate fail $error');
        state = state.copyWith(isCalculateLoading: false);
      },
    );
  }
}
