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

import 'package:base_sdk/src/database/app_database.dart';
import 'package:base_sdk/src/sync/sync_engine.dart';

/// One parked local-first record: its queued push was terminally rejected by
/// the backend (4xx) and needs the manager's attention (park-and-surface).
class SyncIssue {
  const SyncIssue({
    required this.box,
    required this.localId,
    required this.record,
    this.error,
    this.opId,
  });

  /// KV box the record lives in (`manager_shops` / `manager_products` /
  /// `manager_orders`).
  final String box;

  final String localId;

  /// The stored record, including the original request material.
  final Map<String, dynamic> record;

  /// The server's rejection message.
  final String? error;

  /// Outbox id of the parked op that tried to push this record, matched via
  /// the `localId` payload key all three create handlers write. Null when no
  /// parked op references the record (op already gone) — then retry has
  /// nothing to requeue and only discard resolves the issue.
  final String? opId;

  /// Short human-readable label for list display, read from the request
  /// material each box stores (`shop_data` / `product` / `order` maps —
  /// write shapes, same reads as the local stores' `to*Data` builders).
  String get summary {
    switch (box) {
      case 'manager_shops':
        final data = record['shop_data'];
        final name = data is Map ? data['shop_name']?.toString() : null;
        return (name == null || name.isEmpty) ? localId : name;
      case 'manager_products':
        final product = record['product'];
        final titles = product is Map ? product['title'] : null;
        final title = (titles is Map && titles.isNotEmpty)
            ? titles.values.first?.toString()
            : null;
        return (title == null || title.isEmpty) ? localId : title;
      case 'manager_orders':
        final order = record['order'];
        final phone = order is Map ? order['phone']?.toString() : null;
        final type = order is Map ? order['delivery_type']?.toString() : null;
        final parts = [
          if (type != null && type.isNotEmpty) type,
          if (phone != null && phone.isNotEmpty) phone,
        ];
        return parts.isEmpty ? localId : parts.join(' • ');
    }
    return localId;
  }
}

/// Read/resolve API over the parked (`needs_attention`) records of the three
/// manager local-first boxes. Consumed by the sync-issues screen; this
/// service deliberately reads by box name only, so it needs no import of the
/// sibling SDKs that own the other two boxes.
class SyncIssuesService {
  // Box names owned by merchants_sdk (ManagerShopsLocalStore), products_sdk
  // (ManagerProductsLocalStore) and orders_sdk (ManagerOrdersLocalStore);
  // keep in step with those stores.
  static const List<String> boxes = [
    'manager_shops',
    'manager_products',
    'manager_orders',
  ];

  AppDatabase get _db => AppDatabase();

  Future<List<SyncIssue>> listNeedsAttention() async {
    // One parked-ops read up front; each op's payload carries
    // `{"localId": "offline:<uuid>", ...}` (shop.create / product.create /
    // order.create contract), which is how an op maps back to its record.
    final opIdByLocalId = <String, String>{};
    for (final op in await SyncEngine().parkedOps()) {
      try {
        final payload = jsonDecode(op.payload);
        final localId = payload is Map ? payload['localId']?.toString() : null;
        if (localId != null && localId.isNotEmpty) {
          opIdByLocalId[localId] = op.id;
        }
      } catch (_) {
        // Unreadable payload: op cannot be matched to a record; skip.
      }
    }

    final issues = <SyncIssue>[];
    for (final box in boxes) {
      final records = await _db.getAll(box);
      for (final record in records) {
        if (record['needs_attention'] != true) continue;
        final localId = (record['local_id'] ?? record['id'] ?? '').toString();
        issues.add(
          SyncIssue(
            box: box,
            localId: localId,
            record: record,
            error: record['sync_error']?.toString(),
            opId: opIdByLocalId[localId],
          ),
        );
      }
    }
    return issues;
  }

  /// Re-attempt the parked push as-is (the "retry" arm): requeue the outbox
  /// op (attempts and backoff cleared, engine kicked) and put the record
  /// back to `pending_sync`. Returns false — leaving the record parked —
  /// when there is no matching op to requeue, or the op is no longer parked.
  /// Editing the record before retrying is a future enhancement; retry
  /// pushes the payload exactly as originally queued.
  Future<bool> retry(SyncIssue issue) async {
    final opId = issue.opId;
    if (opId == null) return false;
    final requeued = await SyncEngine().retryOp(opId);
    if (!requeued) return false;
    final record = await _db.getItem(issue.box, issue.localId);
    if (record != null) {
      record['needs_attention'] = false;
      record['pending_sync'] = true;
      record.remove('sync_error');
      await _db.putItem(issue.box, issue.localId, record);
    }
    return true;
  }

  /// Discard a parked record (the "discard" arm): delete the local record
  /// and its outbox op, so nothing is left to retry — a parked op would
  /// otherwise sit in the outbox forever, blocking any ops that depend on
  /// it.
  Future<void> discard(SyncIssue issue) async {
    final opId = issue.opId;
    if (opId != null) await SyncEngine().deleteOp(opId);
    await _db.deleteItem(issue.box, issue.localId);
  }
}
