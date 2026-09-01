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
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'kv_tables.dart';
import '../sync/id_mappings_table.dart';
import '../sync/outbox_table.dart';

// @sdk-database-imports-start
import 'injected/auth_sdk__offline_user_table.dart';
// @sdk-database-imports-end

part 'app_database.g.dart';

/// Shared offline database for the composed app.
///
/// base_sdk owns the database shell and a generic JSON document store; SDKs
/// with relational needs register typed tables + migration steps through
/// their manifest.json `database` section, which the composer injects into
/// the cached copy of this file at compose time (the .rokct/cache copy is
/// fully editable by design).
@DriftDatabase(
  tables: [
    KeyValueTable,
    OutboxTable,
    IdMappingsTable,
    // @sdk-database-tables-start
    OfflineUsersTable,
    // @sdk-database-tables-end
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._internal() : super(_openConnection());

  /// Test-only escape hatch: an instance on a caller-supplied executor
  /// (e.g. `NativeDatabase.memory()`), bypassing both the singleton and the
  /// on-device file. Never used by app code.
  @visibleForTesting
  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  /// The database must be a process-wide singleton: multiple SDKs resolve it
  /// independently (directly or via get_it) and drift does not allow two
  /// executors on the same file.
  factory AppDatabase() => _instance ??= AppDatabase._internal();
  static AppDatabase? _instance;

  /// Test-only: point the singleton at [database] (or clear it with null) so
  /// code that resolves `AppDatabase()` internally — SyncEngine does — can be
  /// exercised against an in-memory database.
  @visibleForTesting
  static void debugOverrideInstance(AppDatabase? database) {
    _instance = database;
  }

  /// Base-owned schema versions stay low (< 10); SDK manifests claim higher
  /// numbers through the composer's migration injection (auth is around 16),
  /// and the composer raises this getter in the cached copy accordingly.
  @override
  int get schemaVersion => 16;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Base-owned steps run before SDK-injected ones and guard on their
        // own low version numbers only.
        if (from < 2) {
          await m.createTable(outboxTable);
          await m.createTable(idMappingsTable);
        }
        // @sdk-database-migrations-start
        if (from < 16) { await m.createTable(offlineUsersTable); }
        // @sdk-database-migrations-end
      },
      beforeOpen: (details) async {
        // Safety net for composed apps: injected SDK migrations own the
        // effective schemaVersion there, so a database already past base's
        // own version numbers would skip the onUpgrade step above. Drift's
        // createTable emits CREATE TABLE IF NOT EXISTS, making this
        // idempotent and a no-op once the tables exist.
        final m = createMigrator();
        await m.createTable(outboxTable);
        await m.createTable(idMappingsTable);
      },
    );
  }

  // ─── Generic JSON document store ───

  /// Save a JSON-serializable item by key.
  Future<void> putItem(String boxName, String key, Map<String, dynamic> json) {
    return into(keyValueTable).insertOnConflictUpdate(
      KeyValueTableCompanion.insert(
        box: boxName,
        id: key,
        data: jsonEncode(json),
      ),
    );
  }

  /// Get an item as a Map by key, or null when absent.
  Future<Map<String, dynamic>?> getItem(String boxName, String key) async {
    final query = select(keyValueTable)
      ..where((t) => t.box.equals(boxName) & t.id.equals(key));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return jsonDecode(row.data) as Map<String, dynamic>;
  }

  /// Rows per page for the paged box reads ([getPage], [getAllPaged] and
  /// [getAll]). Bounds how many encoded JSON strings drift materialises at
  /// once; the Feb 2027 Play memory thresholds are measured as P90 anonymous
  /// RSS, and a whole-box read spikes exactly that.
  static const int defaultPageSize = 500;

  /// One keyset page of a box, ordered by row key ascending. Pass the key of
  /// the last row you saw as [afterId] to get the next page; omit it for the
  /// first. Prefer this (or [getAllPaged]) over [getAll] for boxes that can
  /// grow without bound.
  Future<List<Map<String, dynamic>>> getPage(
    String boxName, {
    int limit = defaultPageSize,
    String? afterId,
  }) async {
    final rows = await _rawPage(boxName, limit, afterId);
    return rows.map(_decodeRow).toList();
  }

  /// Every item in a box, streamed one bounded page at a time in row-key
  /// order. The caller decides what to retain, so peak memory is one page
  /// rather than the whole box.
  Stream<List<Map<String, dynamic>>> getAllPaged(
    String boxName, {
    int pageSize = defaultPageSize,
  }) async* {
    String? cursor;
    while (true) {
      final rows = await _rawPage(boxName, pageSize, cursor);
      if (rows.isEmpty) return;
      yield rows.map(_decodeRow).toList();
      if (rows.length < pageSize) return;
      cursor = rows.last.id;
    }
  }

  /// Number of items in a box, without reading any of them.
  Future<int> countBox(String boxName) async {
    final count = keyValueTable.id.count();
    final query = selectOnly(keyValueTable)
      ..addColumns([count])
      ..where(keyValueTable.box.equals(boxName));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Get all items in a box. Each map includes its row key under 'id'
  /// (without overwriting an 'id' already present in the stored data).
  ///
  /// Reads in [defaultPageSize] pages rather than materialising the whole
  /// box in one query, so the transient row set stays bounded. The returned
  /// list is still the whole box by contract, so callers that only need part
  /// of it should move to [getPage] / [getAllPaged]. Rows now come back in
  /// row-key order; the unpaged version left the order unspecified.
  Future<List<Map<String, dynamic>>> getAll(String boxName) async {
    final out = <Map<String, dynamic>>[];
    await for (final page in getAllPaged(boxName)) {
      out.addAll(page);
    }
    return out;
  }

  Future<List<KeyValueEntity>> _rawPage(
    String boxName,
    int limit,
    String? afterId,
  ) {
    final query = select(keyValueTable)
      ..where(
        (t) => afterId == null
            ? t.box.equals(boxName)
            : t.box.equals(boxName) & t.id.isBiggerThanValue(afterId),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.id)])
      ..limit(limit);
    return query.get();
  }

  Map<String, dynamic> _decodeRow(KeyValueEntity row) {
    final map = jsonDecode(row.data) as Map<String, dynamic>;
    map.putIfAbsent('id', () => row.id);
    return map;
  }

  /// Delete an item by key.
  Future<void> deleteItem(String boxName, String key) {
    return (delete(keyValueTable)
          ..where((t) => t.box.equals(boxName) & t.id.equals(key)))
        .go();
  }

  /// Clear all items in a box. Returns the number of deleted rows.
  Future<int> clearBox(String boxName) {
    return (delete(keyValueTable)..where((t) => t.box.equals(boxName))).go();
  }

  /// Hand SQLite's page cache and scratch buffers back to the allocator
  /// without closing the connection.
  ///
  /// This is the memory lever that is actually safe to pull on this
  /// database: [close] is not, because the instance is a process-wide
  /// singleton that other SDKs hold directly and the outbox drain can be
  /// mid-flight (see MemoryPressureService for the full reasoning). Best
  /// effort by design - a closed or busy connection is not an error here.
  Future<void> releaseMemory() async {
    try {
      await customStatement('PRAGMA shrink_memory');
    } catch (_) {
      // Nothing to do: releasing cache is an optimisation, never a
      // correctness requirement.
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'rokct_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
