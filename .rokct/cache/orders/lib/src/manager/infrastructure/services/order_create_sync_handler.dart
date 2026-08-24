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

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:base_sdk/src/database/app_database.dart';
import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/sync/sync_handler.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/response/create_order_response.dart';

import 'manager_orders_local_store.dart';

/// Pushes `order.create` outbox ops: a POS sale recorded while the backend
/// was unreachable is created for real the next time the SyncEngine drains —
/// first the order, then (best effort) its payment transaction. Registered
/// with the engine in `ManagerOrdersDependencies.register`.
///
/// Payload contract (written by `SellerOrdersRepository.createOrder`):
/// `{"localId": "offline:<uuid>", "order": {...create_order body...},
/// "payment_id": <String?>}`. `dependsOn` carries the ops minting any temp
/// entities the body references (offline shop / products), so by the time
/// this handler runs the engine has rewritten those tokens to backend ids.
class OrderCreateSyncHandler extends SyncHandler {
  /// Op type this handler serves.
  static const String opType = 'order.create';

  /// `sdk` column value for ops this SDK enqueues.
  static const String sdkName = 'orders_sdk';

  @override
  Future<SyncResult> push(OutboxEntry op) async {
    final Map<String, dynamic> payload;
    try {
      // op.payload, not the KV record: the engine rewrites temp-id tokens in
      // pending payloads as parent ops sync.
      payload = jsonDecode(op.payload) as Map<String, dynamic>;
    } catch (e) {
      return SyncResult.rejected('order.create payload unreadable: $e');
    }
    final localId = (payload['localId'] ?? '') as String;
    if (localId.isEmpty) {
      return const SyncResult.rejected('order.create op missing localId');
    }

    final record = await ManagerOrdersLocalStore.get(localId);
    if (record == null) {
      // Record discarded locally since enqueue; nothing left to push.
      return const SyncResult.synced();
    }
    if (record['synced'] == true) {
      final backendId = record['backend_id']?.toString();
      return SyncResult.synced(
        idMappings: backendId == null ? const {} : {localId: backendId},
        entityType: 'order',
      );
    }

    final order = (payload['order'] as Map?)?.cast<String, dynamic>() ?? {};
    _restoreReferenceIds(order);
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await const PlatformGateway().call(
        'api.order.create_order',
        payload: {'order_data': order},
        // op.id doubles as the idempotency key so an ambiguous-failure retry
        // does not double-create (backend dedupe per the Phase 0 contract).
        options: Options(headers: {'X-Idempotency-Key': op.id}),
      );
      final String? backendId =
          CreateOrderResponse.fromJson(response).data?.id;
      await ManagerOrdersLocalStore.markSynced(
        localId,
        backendId: backendId,
      );
      await _createTransaction(client, op.id, backendId, payload['payment_id']);
      return SyncResult.synced(
        idMappings: backendId == null ? const {} : {localId: backendId},
        entityType: 'order',
      );
    } catch (e) {
      // getDioStatus maps connection failures and timeouts to 500, so
      // >= 500 (plus 408) is transient; a concrete 4xx parks the record
      // with the server's message (park-and-surface).
      final status = NetworkExceptions.getDioStatus(e);
      final message = AppHelpers.errorHandler(e);
      if (status >= 400 && status < 500 && status != 408) {
        await ManagerOrdersLocalStore.markNeedsAttention(localId, message);
        return SyncResult.rejected(message);
      }
      return SyncResult.retryable(message);
    }
  }

  /// The engine's temp-id substitution replaces `offline:<uuid>` tokens with
  /// backend ids as JSON *strings* — which is exactly what the backend
  /// expects: reference ids are Frappe docnames (hash strings), never
  /// numeric. This normalizes any legacy numeric value to its string form
  /// and otherwise passes the payload through untouched.
  void _restoreReferenceIds(Map<String, dynamic> order) {
    String? asId(dynamic v) => v?.toString();
    final shopId = asId(order['shop_id']);
    if (shopId != null) order['shop_id'] = shopId;
    final userId = asId(order['user_id']);
    if (userId != null) order['user_id'] = userId;
    final products = order['products'];
    if (products is List) {
      for (final product in products) {
        if (product is! Map) continue;
        final stockId = asId(product['stock_id']);
        if (stockId != null) product['stock_id'] = stockId;
      }
    }
  }

  /// Best effort, matching the online POS flow where a failed transaction
  /// only shows a snackbar: returning retryable here would re-run the whole
  /// op and re-create the order, which is worse than a missing transaction.
  Future<void> _createTransaction(
    Dio client,
    String opId,
    String? orderId,
    dynamic paymentId,
  ) async {
    // Payment ids are Payment docname strings (legacy queued payloads may
    // still carry ints; either way the wire value is its string form).
    final String? paymentDocname =
        (paymentId is String || paymentId is int) ? paymentId.toString() : null;
    if (orderId == null || paymentDocname == null) return;
    try {
      await client.post(
        '/api/method/paas.api.payment.create_order_transaction',
        data: {'order_id': orderId, 'payment_sys_id': paymentDocname},
        // Derived from the same op id as the order-create call but
        // distinct from it — the two creates must not share a key (the
        // server stores one response per key per endpoint).
        options: Options(headers: {'X-Idempotency-Key': '$opId:txn'}),
      );
    } catch (e) {
      debugPrint('==> queued order transaction failed (order $orderId): $e');
    }
  }
}
