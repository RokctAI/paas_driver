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

import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:base_sdk/src/database/app_database.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/sync/sync_handler.dart';

import 'manager_shops_local_store.dart';

/// Pushes `shop.create` outbox ops: a shop created while the backend was
/// unreachable is created for real the next time the SyncEngine drains
/// (boot / connectivity regain). Registered with the engine in
/// `ManagerMerchantsDependencies.register`.
///
/// Payload contract (written by `SellerShopRepository.createShop`):
/// `{"localId": "offline:<uuid>", "shop_data": {...}}`.
class ShopCreateSyncHandler extends SyncHandler {
  /// Op type this handler serves.
  static const String opType = 'shop.create';

  /// `sdk` column value for ops this SDK enqueues.
  static const String sdkName = 'merchants_sdk';

  @override
  Future<SyncResult> push(OutboxEntry op) async {
    final Map<String, dynamic> payload;
    try {
      payload = jsonDecode(op.payload) as Map<String, dynamic>;
    } catch (e) {
      return SyncResult.rejected('shop.create payload unreadable: $e');
    }
    final localId = (payload['localId'] ?? '') as String;
    if (localId.isEmpty) {
      return const SyncResult.rejected('shop.create op missing localId');
    }

    final record = await ManagerShopsLocalStore.get(localId);
    if (record == null) {
      // Record discarded locally since enqueue; nothing left to push.
      return const SyncResult.synced();
    }
    if (record['synced'] == true) {
      final backendId = record['backend_id']?.toString();
      return SyncResult.synced(
        idMappings: backendId == null ? const {} : {localId: backendId},
        entityType: 'shop',
      );
    }

    try {
      final response = await const PlatformGateway().call(
        'api.shop.create_shop',
        payload: {'shop_data': payload['shop_data']},
        // op.id doubles as the idempotency key so an ambiguous-failure retry
        // does not double-create (backend dedupe per the Phase 0 contract).
        options: Options(headers: {'X-Idempotency-Key': op.id}),
      );
      final backendId = extractBackendShopId(response);
      await ManagerShopsLocalStore.markSynced(localId, backendId: backendId);
      await _swapCachedShopId(localId, backendId);
      return SyncResult.synced(
        idMappings: backendId == null ? const {} : {localId: backendId},
        entityType: 'shop',
      );
    } catch (e) {
      // NetworkExceptions.getDioStatus maps connection failures and timeouts
      // to 500, so >= 500 (plus 408) is "backend unreachable / transient"; a
      // concrete 4xx is a definitive rejection to park with the server's
      // message (park-and-surface).
      final status = NetworkExceptions.getDioStatus(e);
      final message = AppHelpers.errorHandler(e);
      if (status >= 400 && status < 500 && status != 408) {
        await ManagerShopsLocalStore.markNeedsAttention(localId, message);
        return SyncResult.rejected(message);
      }
      return SyncResult.retryable(message);
    }
  }

  /// `create_shop`'s response shape is not pinned by the endpoint contract
  /// yet, so the id is read defensively; a missing id only means the local
  /// record keeps its temp id until the next `getMyShop` refresh.
  static String? extractBackendShopId(dynamic data) {
    if (data is! Map) return null;
    final dynamic direct = data['id'] ??
        (data['data'] is Map ? data['data']['id'] : null) ??
        (data['shop'] is Map ? data['shop']['id'] : null);
    return direct?.toString();
  }

  /// The offline create seeds `LocalStorage.setShopJson` with the temp id so
  /// product/order payloads can reference the shop; swap it for the backend
  /// id once known.
  Future<void> _swapCachedShopId(String localId, String? backendId) async {
    if (backendId == null) return;
    final cached = LocalStorage.getShopJson();
    if (cached == null || cached['id']?.toString() != localId) return;
    cached['id'] = backendId;
    cached.remove('pending_sync');
    await LocalStorage.setShopJson(cached);
  }
}
