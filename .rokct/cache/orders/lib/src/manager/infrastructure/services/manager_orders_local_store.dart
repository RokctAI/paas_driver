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

import 'package:base_sdk/src/database/app_database.dart';
import 'package:base_sdk/src/sync/sync_engine.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/order_data.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/user_data.dart';

/// Local-first records for manager-created (POS) orders, kept in base_sdk's
/// shared KV store (box `manager_orders`).
///
/// Same life cycle as merchants_sdk's `ManagerShopsLocalStore`: written
/// through on every `createOrder`, deleted again when the direct backend
/// call succeeds, kept as `pending_sync` when it does not. Unlike shops and
/// products the synced record is kept (with `backend_id`) rather than
/// removed at drain time — the POS keys on the local id throughout, so the
/// order simply gains its backend id and loses the pending badge.
class ManagerOrdersLocalStore {
  ManagerOrdersLocalStore._();

  static const String box = 'manager_orders';

  static AppDatabase get _db => AppDatabase();

  static Future<void> putPending(
    String localId,
    Map<String, dynamic> record,
  ) =>
      _db.putItem(box, localId, {
        ...record,
        'local_id': localId,
        'pending_sync': true,
        'synced': false,
        'needs_attention': false,
        'created_at': DateTime.now().toIso8601String(),
      });

  static Future<Map<String, dynamic>?> get(String localId) =>
      _db.getItem(box, localId);

  static Future<void> delete(String localId) => _db.deleteItem(box, localId);

  static Future<void> markSynced(
    String localId, {
    String? backendId,
  }) async {
    final record = await _db.getItem(box, localId);
    if (record == null) return;
    record['pending_sync'] = false;
    record['synced'] = true;
    record['needs_attention'] = false;
    record.remove('sync_error');
    if (backendId != null) record['backend_id'] = backendId;
    await _db.putItem(box, localId, record);
  }

  static Future<void> markNeedsAttention(String localId, String error) async {
    final record = await _db.getItem(box, localId);
    if (record == null) return;
    record['pending_sync'] = false;
    record['needs_attention'] = true;
    record['sync_error'] = error;
    await _db.putItem(box, localId, record);
  }

  /// Records not yet reconciled with the backend (pending or parked).
  static Future<List<Map<String, dynamic>>> unsynced() async =>
      (await _db.getAll(box)).where((r) => r['synced'] != true).toList();

  /// [unsynced] as list rows for the manager's order queues merge.
  static Future<List<OrderData>> unsyncedAsOrders() async =>
      (await unsynced()).map(toOrderData).toList();

  /// Every `offline:<uuid>` token inside [json] — the temp entities this
  /// payload references (shop, products created offline).
  static Set<String> offlineTokensIn(String json) =>
      RegExp('$kOfflineIdPrefix[0-9a-fA-F-]+')
          .allMatches(json)
          .map((m) => m.group(0)!)
          .toSet();

  /// Outbox op ids that mint any of [tempIds] — the `dependsOn` parents for
  /// an op referencing those temp entities.
  static Future<List<String>> pendingOpIdsCreating(
    Iterable<String> tempIds,
  ) async {
    if (tempIds.isEmpty) return const [];
    final db = _db;
    final rows = await db.select(db.outboxTable).get();
    return [
      // tempIds column is a JSON list; substring containment is sound
      // because temp ids are globally unique prefixed uuid tokens.
      for (final row in rows)
        if (tempIds.any(row.tempIds.contains)) row.id,
    ];
  }

  /// Builds a queue row from a stored record. The record holds the
  /// `create_order` request map (write shape), so only the fields that shape
  /// carries are populated — enough for the list tile and its badge.
  static OrderData toOrderData(Map<String, dynamic> record) {
    final order =
        (record['order'] as Map?)?.cast<String, dynamic>() ?? const {};
    final localId = (record['local_id'] ?? record['id'] ?? '').toString();
    final phone = order['phone']?.toString();
    return OrderData(
      status: 'new',
      deliveryType: order['delivery_type']?.toString(),
      deliveryDate: order['delivery_date']?.toString(),
      createdAt: record['created_at']?.toString(),
      user: phone == null ? null : UserData(phone: phone),
    )
      ..localId = localId
      ..pendingSync = record['synced'] != true
      ..needsAttention = record['needs_attention'] == true
      ..syncError = record['sync_error']?.toString();
  }
}
