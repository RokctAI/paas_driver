import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:base_sdk/src/database/app_database.dart';
import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
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
      final client = dioHttp.client(requireAuth: true);
      final response = await client.post(
        '/api/method/paas.api.seller_product.seller_product.create_product',
        data: payload['product'],
        // op.id doubles as the idempotency key so an ambiguous-failure retry
        // does not double-create (backend dedupe per the Phase 0 contract).
        options: Options(headers: {'X-Idempotency-Key': op.id}),
      );
      final data = response.data is Map ? response.data['data'] : null;
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
