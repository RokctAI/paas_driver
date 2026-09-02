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

import 'package:base_sdk/src/database/app_database.dart';

/// Local-first records for manager-created shops, kept in base_sdk's shared
/// KV store (box `manager_shops`).
///
/// A record is written on every `createShop` call (write-through). When the
/// direct backend call succeeds the record is deleted again — the backend is
/// authoritative and reachable. When the backend is unreachable the record
/// stays with `pending_sync: true`, backing the pending-merge UI, until
/// `ShopCreateSyncHandler` drains the queued op and marks it synced (or
/// `needs_attention` on a terminal 4xx, per the park-and-surface policy).
class ManagerShopsLocalStore {
  ManagerShopsLocalStore._();

  static const String box = 'manager_shops';

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
}
