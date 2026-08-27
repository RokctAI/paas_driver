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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/domain/interface/payments.dart';
import 'package:base_sdk/src/application/payment_methods/payment_state.dart';
import 'package:base_sdk/src/handlers/api_result.dart';

class PaymentNotifier extends StateNotifier<PaymentState> {
  final PaymentsRepositoryFacade _paymentsRepository;

  PaymentNotifier(this._paymentsRepository) : super(const PaymentState());

  void change(int index) {
    state = state.copyWith(currentIndex: index);
  }

  Future<void> fetchPayments(
    BuildContext context, {
    bool withOutCash = false,
    bool shopEnableCod = true,
  }) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      state = state.copyWith(isPaymentsLoading: true);
      final response = await _paymentsRepository.getPayments();
      response.when(
        success: (data) {
          List payments = [];
          if (withOutCash || !shopEnableCod) {
            payments =
                data?.data?.reversed.where((e) => e.tag != "cash").toList() ??
                    [];
          } else {
            payments = data?.data?.reversed.toList() ?? [];
          }
          state = state.copyWith(payments: payments, isPaymentsLoading: false);
        },
        failure: (failure, status) {
          state = state.copyWith(isPaymentsLoading: false);
          AppHelpers.showCheckTopSnackBar(
            context,
            AppHelpers.getTranslation(status.toString()),
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
