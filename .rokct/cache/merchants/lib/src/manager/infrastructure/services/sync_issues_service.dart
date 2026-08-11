import 'package:base_sdk/src/database/app_database.dart';

/// One parked local-first record: its queued push was terminally rejected by
/// the backend (4xx) and needs the manager's attention (park-and-surface).
class SyncIssue {
  const SyncIssue({
    required this.box,
    required this.localId,
    required this.record,
    this.error,
  });

  /// KV box the record lives in (`manager_shops` / `manager_products` /
  /// `manager_orders`).
  final String box;

  final String localId;

  /// The stored record, including the original request material.
  final Map<String, dynamic> record;

  /// The server's rejection message.
  final String? error;
}

/// Read API over the parked (`needs_attention`) records of the three manager
/// local-first boxes. Consumed by a badge / future sync-issues screen; this
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
    final issues = <SyncIssue>[];
    for (final box in boxes) {
      final records = await _db.getAll(box);
      for (final record in records) {
        if (record['needs_attention'] != true) continue;
        issues.add(
          SyncIssue(
            box: box,
            localId: (record['local_id'] ?? record['id'] ?? '').toString(),
            record: record,
            error: record['sync_error']?.toString(),
          ),
        );
      }
    }
    return issues;
  }

  /// Discard a parked record (the "discard" arm of edit-and-retry/discard).
  Future<void> discard(SyncIssue issue) =>
      _db.deleteItem(issue.box, issue.localId);
}
