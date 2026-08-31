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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:base_sdk/src/handlers/handlers.dart';

import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

import 'collect_conversion_state.dart';

/// Runs the ONE atomic conversion behind the "Customer is here" lane.
///
/// It calls exactly one endpoint and holds exactly one outcome. There is
/// deliberately no client-side sequence here — no "flip the type, then
/// unassign, then refund": a partial failure would leave an order that
/// is half converted, and the settlement ordering that keeps the driver
/// from being paid twice is not something a client can be trusted to
/// hold across a dropped connection.
class CollectConversionNotifier extends StateNotifier<CollectConversionState> {
  final SellerOrdersRepositoryFacade _repository;

  CollectConversionNotifier(this._repository)
      : super(const CollectConversionState());

  Future<void> convert({
    required String orderId,
    void Function(CollectConversion result)? onSuccess,
    void Function(String message)? onFailure,
  }) async {
    if (state.isConverting || state.isDone) return;
    state = state.copyWith(isConverting: true, error: null);
    final response = await _repository.convertDeliveryToCollected(
      orderId: orderId,
    );
    response.when(
      success: (data) {
        state = state.copyWith(isConverting: false, result: data);
        onSuccess?.call(data);
      },
      failure: (failure, status) {
        final message = failure.toString();
        state = state.copyWith(isConverting: false, error: message);
        onFailure?.call(message);
      },
    );
  }

  /// Forget the last outcome — the detail pane is reused across orders.
  void reset() => state = const CollectConversionState();
}
