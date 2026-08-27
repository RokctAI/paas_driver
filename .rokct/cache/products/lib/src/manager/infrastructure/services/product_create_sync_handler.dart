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

import 'manager_products_local_store.dart';

/// Pushes `product.create` outbox ops: a product added while the backend was
/// unreachable is created for real the next time the SyncEngine drains.
/// Registered with the engine in `ProductsSdkDependencies.register`.
///
/// Payload contract (written by `SellerProductsRepository.createProduct`):
/// `{"localId": "offline:<uuid>", "product": {...create_product body...}}`.
/// When the product was added against a shop that was itself created
/// offline, the op carries `dependsOn` of the `shop.create` op, so this
/// handler only ever runs once the shop exists backend-side.
class ProductCreateSyncHandler extends SyncHandler {
  /// Op type this handler serves.
  static const String opType = 'product.create';

  /// `sdk` column value for ops this SDK enqueues.
  static const String sdkName = 'products_sdk';

  @override
  Future<SyncResult> push(OutboxEntry op) async {
    final Map<String, dynamic> payload;
    try {
      // op.payload, not the KV record: the engine rewrites temp-id tokens in
      // pending payloads as parent ops sync.
      payload = jsonDecode(op.payload) as Map<String, dynamic>;
    } catch (e) {
      return SyncResult.rejected('product.create payload unreadable: $e');
    }
    final localId = (payload['localId'] ?? '') as String;
    if (localId.isEmpty) {
      return const SyncResult.rejected('product.create op missing localId');
    }

    final record = await ManagerProductsLocalStore.get(localId);
    if (record == null) {
      // Record discarded locally since enqueue; nothing left to push.
      return const SyncResult.synced();
    }
    if (record['synced'] == true) {
      final backendId = record['backend_id']?.toString();
      return SyncResult.synced(
        idMappings: backendId == null ? const {} : {localId: backendId},
        entityType: 'product',
      );
    }

    try {
      // merchants' seller_product.create_product(product_data) via the
      // universal platform gateway (whitelisted-method key registered
      // alongside this change in merchants/frappe/manifest.json).
      final response = await const PlatformGateway().call(
        'api.seller_product.create_product',
        payload: {'product_data': payload['product']},
        // op.id doubles as the idempotency key so an ambiguous-failure retry
        // does not double-create (backend dedupe per the Phase 0 contract).
        options: Options(headers: {'X-Idempotency-Key': op.id}),
      );
      final data = response is Map ? response['data'] : null;
      final backendId =
          data is Map ? data['id']?.toString() : null;
      final backendUuid =
          data is Map ? data['uuid']?.toString() : null;
      await ManagerProductsLocalStore.markSynced(
        localId,
        backendId: backendId,
        backendUuid: backendUuid,
      );
      final mappedId = backendId ?? backendUuid;
      return SyncResult.synced(
        idMappings: mappedId == null ? const {} : {localId: mappedId},
        entityType: 'product',
      );
    } catch (e) {
      // getDioStatus maps connection failures and timeouts to 500, so
      // >= 500 (plus 408) is transient; a concrete 4xx parks the record
      // with the server's message (park-and-surface).
      final status = NetworkExceptions.getDioStatus(e);
      final message = AppHelpers.errorHandler(e);
      if (status >= 400 && status < 500 && status != 408) {
        await ManagerProductsLocalStore.markNeedsAttention(localId, message);
        return SyncResult.rejected(message);
      }
      return SyncResult.retryable(message);
    }
  }
}
