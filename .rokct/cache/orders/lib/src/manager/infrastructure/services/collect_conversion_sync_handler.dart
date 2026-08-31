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

import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:base_sdk/src/database/app_database.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/sync/sync_handler.dart';

/// Pushes `order.collect_in_person` outbox ops (design strip section 43,
/// frame 43e).
///
/// The customer is standing at the counter, so the goods go over it
/// whether or not the backend is reachable — refusing to hand them over
/// is the one thing that must never happen. What CANNOT happen offline
/// is the decision: whether a driver was assigned and whether the fee
/// goes back to a wallet are both server state. So the till records the
/// hand-over and this handler runs the real conversion on reconnect.
///
/// The endpoint is idempotent (`already_converted`), so a retry after an
/// ambiguous failure converts nothing twice and moves no money twice.
/// A definitive 4xx parks the op — it surfaces in Sync issues rather
/// than silently reverting a hand-over that already happened.
///
/// Payload contract (written by
/// `SellerOrdersRepository.convertDeliveryToCollected`):
/// `{"order_id": "<Order docname>"}`.
class CollectConversionSyncHandler extends SyncHandler {
  /// Op type this handler serves.
  static const String opType = 'order.collect_in_person';

  /// `sdk` column value for ops this SDK enqueues.
  static const String sdkName = 'orders_sdk';

  @override
  Future<SyncResult> push(OutboxEntry op) async {
    final Map<String, dynamic> payload;
    try {
      payload = jsonDecode(op.payload) as Map<String, dynamic>;
    } catch (e) {
      return SyncResult.rejected(
        'order.collect_in_person payload unreadable: $e',
      );
    }
    final orderId = (payload['order_id'] ?? '').toString();
    if (orderId.isEmpty) {
      return const SyncResult.rejected(
        'order.collect_in_person op missing order_id',
      );
    }
    try {
      await const PlatformGateway().call(
        'api.seller_order.convert_delivery_to_collected',
        payload: {'order_id': orderId},
        options: Options(headers: {'X-Idempotency-Key': op.id}),
      );
      return const SyncResult.synced();
    } catch (e) {
      // getDioStatus maps connection failures and timeouts to 500, so
      // >= 500 (plus 408) is transient; a concrete 4xx is the backend
      // saying no, and parks with its message (park-and-surface).
      final status = NetworkExceptions.getDioStatus(e);
      final message = AppHelpers.errorHandler(e);
      if (status >= 400 && status < 500 && status != 408) {
        return SyncResult.rejected(message);
      }
      return SyncResult.retryable(message);
    }
  }
}
