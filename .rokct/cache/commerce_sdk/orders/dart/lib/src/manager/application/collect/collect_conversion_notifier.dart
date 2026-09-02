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
