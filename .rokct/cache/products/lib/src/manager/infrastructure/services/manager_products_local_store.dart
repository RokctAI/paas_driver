import 'package:base_sdk/src/database/app_database.dart';
import 'package:base_sdk/src/models/data/translation.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_product_data.dart';

/// Local-first records for manager-created products, kept in base_sdk's
/// shared KV store (box `manager_products`).
///
/// Same life cycle as merchants_sdk's `ManagerShopsLocalStore`: written
/// through on every `createProduct`, deleted again when the direct backend
/// call succeeds, kept as `pending_sync` when it does not, marked synced or
/// `needs_attention` by `ProductCreateSyncHandler` at drain time.
class ManagerProductsLocalStore {
  ManagerProductsLocalStore._();

  static const String box = 'manager_products';

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
    String? backendUuid,
  }) async {
    final record = await _db.getItem(box, localId);
    if (record == null) return;
    record['pending_sync'] = false;
    record['synced'] = true;
    record['needs_attention'] = false;
    record.remove('sync_error');
    if (backendId != null) record['backend_id'] = backendId;
    if (backendUuid != null) record['backend_uuid'] = backendUuid;
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

  /// [unsynced] as list rows for the manager's product list merge.
  static Future<List<SellerProductData>> unsyncedAsProducts() async =>
      (await unsynced()).map(toProductData).toList();

  /// Outbox op ids that mint any of [tempIds] — the `dependsOn` parents for
  /// an op referencing those temp entities (e.g. a product created against a
  /// shop that is itself still `offline:`).
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

  /// Builds a list row from a stored record. The record holds the
  /// `create_product` request map (write shape), so only the fields that
  /// shape carries are populated — enough for the list tile and its badge.
  static SellerProductData toProductData(Map<String, dynamic> record) {
    final product =
        (record['product'] as Map?)?.cast<String, dynamic>() ?? const {};
    final titles = (product['title'] as Map?) ?? const {};
    final descriptions = (product['description'] as Map?) ?? const {};
    final images = product['images'];
    final localId = (record['local_id'] ?? record['id'] ?? '').toString();
    return SellerProductData(
      uuid: localId,
      shopId: null,
      categoryId: (product['category_id'] as num?)?.toInt(),
      unitId: (product['unit_id'] as num?)?.toInt(),
      tax: product['tax'] as num?,
      interval: product['interval'] as num?,
      minQty: (product['min_qty'] as num?)?.toInt(),
      maxQty: (product['max_qty'] as num?)?.toInt(),
      active: product['active'] == 1 || product['active'] == true,
      addon: product['addon'] == 1,
      img: images is List && images.isNotEmpty
          ? images.first?.toString()
          : null,
      translation: Translation(
        title: titles.isEmpty ? null : titles.values.first?.toString(),
        description: descriptions.isEmpty
            ? null
            : descriptions.values.first?.toString(),
      ),
    )
      ..localId = localId
      ..pendingSync = record['synced'] != true
      ..needsAttention = record['needs_attention'] == true
      ..syncError = record['sync_error']?.toString();
  }
}
