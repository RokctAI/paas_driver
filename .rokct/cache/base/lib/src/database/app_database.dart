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
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
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

  /// The database must be a process-wide singleton: multiple SDKs resolve it
  /// independently (directly or via get_it) and drift does not allow two
  /// executors on the same file.
  factory AppDatabase() => _instance ??= AppDatabase._internal();
  static AppDatabase? _instance;

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

  /// Get all items in a box. Each map includes its row key under 'id'
  /// (without overwriting an 'id' already present in the stored data).
  Future<List<Map<String, dynamic>>> getAll(String boxName) async {
    final query = select(keyValueTable)..where((t) => t.box.equals(boxName));
    final rows = await query.get();
    return rows.map((row) {
      final map = jsonDecode(row.data) as Map<String, dynamic>;
      map.putIfAbsent('id', () => row.id);
      return map;
    }).toList();
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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'rokct_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
