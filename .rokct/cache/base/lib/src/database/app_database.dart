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
import 'owner_scope.dart';
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

  /// Base-owned schema versions used to stay low (< 10), leaving the shared
  /// namespace to the SDK manifests. Owner scoping broke that habit and had
  /// to: the composer substitutes this getter with the MAXIMUM version any
  /// composed manifest declares, so a base-owned number below that maximum is
  /// simply erased, and a device already sitting at the maximum runs no
  /// migration at all. base_sdk therefore claims a number of its own in
  /// base/dart/manifest.json - 19, above every version read across the fleet
  /// (radio 18, productivity 17, auth 16, agent/replay/subscriptions 15,
  /// polaris 13, fav 12) - and this getter matches it so an UNCOMPOSED
  /// base_sdk migrates the same way a composed app does.
  @override
  int get schemaVersion => 19;

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
        if (from < 19) { await ensureOwnerScopeColumns(); }
        // @sdk-database-migrations-end
      },
      beforeOpen: (details) async {
        // A FLOOR under the onUpgrade path above, never a replacement for
        // correct migration numbering.
        //
        // Every composed SDK manifest declares database.migration.version
        // into ONE shared namespace. The composer takes the MAXIMUM across
        // all manifests as the schemaVersion it substitutes above, and
        // concatenates every SDK's step into the single onUpgrade between the
        // markers. Two SDKs that land on the same number - or a table
        // registered with no matching step - leave an upgrading device whose
        // stored user_version ALREADY equals that maximum, so drift runs no
        // migration at all: not onCreate (the file exists) and not onUpgrade
        // (the versions match). A table that is in the schema is then never
        // created, and the first query against it throws. Fresh installs look
        // fine throughout, because onCreate calls createAll - which is
        // exactly what makes the bug so easy to ship.
        //
        // So every table in the schema gets a create here, not the two
        // base-owned ones by name, and this runs on EVERY open rather than
        // only when details.hadUpgrade is true: the collision case is
        // precisely the one where versionBefore == versionNow and hadUpgrade
        // is therefore false, so gating on an upgrade would skip the failure
        // this exists to catch. Cost in the steady state is one sqlite_master
        // read - the loop issues DDL only for a table that is genuinely
        // absent. Drift's createTable emits CREATE TABLE IF NOT EXISTS
        // (drift 2.28), so even an unfiltered create would be idempotent and
        // would leave existing rows untouched.
        final existing = await _existingTableNames();
        final m = createMigrator();
        for (final table in allTables) {
          if (existing.contains(table.actualTableName)) continue;
          await m.createTable(table);
        }
        // The same floor, one level down: a COLUMN the numbering slip skipped.
        // The loop above only ever creates a whole missing table, and the
        // owner-scoping step lives in an SDK-injected migration, so a device
        // whose stored user_version already equals the composed maximum would
        // otherwise open a key_value_table that has no `owner` column at all
        // and throw on its first read. Idempotent and self-checking, so
        // running it here on every open, in the injected migration step, or in
        // both, comes to the same thing.
        await ensureOwnerScopeColumns();
      },
    );
  }

  /// Brings the two owner-scoped tables up to the current definition when the
  /// opened file predates owner scoping, and does nothing at all when it does
  /// not.
  ///
  /// A plain `ALTER TABLE ... ADD COLUMN` is not enough: `owner` joins the
  /// PRIMARY KEY of both tables (so two accounts can hold the same key), and
  /// SQLite cannot alter a primary key in place. So each table is rebuilt the
  /// long way round - rename the old one aside, create the new one from its
  /// current Dart definition, copy every column the two have in common, drop
  /// the old one. `owner` is not among those columns, so every row already on
  /// the device takes its `''` default and comes out unowned, which is exactly
  /// the state the visibility rule treats as the current user's. Nothing is
  /// deleted and no owner is guessed.
  ///
  /// Written out rather than handed to drift's `TableMigration`, which is
  /// marked experimental: this runs on devices with real user data on them,
  /// and the four statements below are worth being able to read.
  ///
  /// Returns the tables it actually rebuilt, which is what the tests assert on.
  Future<List<String>> ensureOwnerScopeColumns() async {
    final rebuilt = <String>[];
    final m = createMigrator();
    for (final table in <TableInfo<Table, dynamic>>[
      keyValueTable,
      outboxTable,
    ]) {
      final name = table.actualTableName;
      final before = await _columnNames(name);
      // An absent table has no columns at all; the table floor above creates
      // it whole, with the owner column already in it.
      if (before.isEmpty || before.contains('owner')) continue;
      final carried = before
          .where(table.columnsByName.containsKey)
          .map((c) => '"$c"')
          .join(', ');
      final parked = '${name}_pre_owner_scope';
      await customStatement('DROP TABLE IF EXISTS "$parked"');
      await customStatement('ALTER TABLE "$name" RENAME TO "$parked"');
      await m.createTable(table);
      if (carried.isNotEmpty) {
        await customStatement(
          'INSERT INTO "$name" ($carried) SELECT $carried FROM "$parked"',
        );
      }
      await customStatement('DROP TABLE "$parked"');
      rebuilt.add(name);
    }
    return rebuilt;
  }

  /// Column names [table] has in the opened file, empty when there is no such
  /// table. Reads `pragma_table_info` as a table-valued function so the name
  /// binds as a parameter instead of being interpolated into SQL.
  Future<List<String>> _columnNames(String table) async {
    final rows = await customSelect(
      'SELECT name FROM pragma_table_info(?1)',
      variables: [Variable<String>(table)],
    ).get();
    return rows.map((row) => row.read<String>('name')).toList();
  }

  /// Hand every row owned by [from] to [to], in both owner-scoped tables.
  ///
  /// The temp-local account's one moving part. A temp-local session owns its
  /// rows as `offline:<local user id>` (the only identity on the device while
  /// it is offline - see [OwnerScope.defaultResolver]); the moment auth syncs
  /// that account the device starts calling it by its backend user id instead,
  /// and without this the account would come back from its first sync unable
  /// to see the work it did before. [SyncEngine] calls it as each temp id
  /// resolves to a backend id, and it is public so an SDK that resolves an
  /// identity by another route can call it too.
  ///
  /// Returns the number of rows moved. A no-op when [from] and [to] are equal
  /// or either is [kUnownedOwner]: promoting unowned rows to an owner is a
  /// backfill guess, which is exactly what this must never do.
  Future<int> adoptOwner(String from, String to) async {
    if (from == to || from == kUnownedOwner || to == kUnownedOwner) return 0;
    final moved =
        await (update(keyValueTable)..where((t) => t.owner.equals(from)))
            .write(KeyValueTableCompanion(owner: Value(to)));
    final movedOps =
        await (update(outboxTable)..where((t) => t.owner.equals(from)))
            .write(OutboxTableCompanion(owner: Value(to)));
    return moved + movedOps;
  }

  /// Names of the tables that actually exist in the opened file, read
  /// straight from sqlite_master. One query, so the [beforeOpen] floor can
  /// skip the tables that are already there instead of issuing DDL per table
  /// on every launch.
  Future<Set<String>> _existingTableNames() async {
    final rows = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    ).get();
    return rows.map((row) => row.read<String>('name')).toSet();
  }

  // ─── Generic JSON document store ───

  /// The account rows written now belong to, and whose rows reads return.
  String get currentOwner => OwnerScope.instance.current;

  /// Save a JSON-serializable item by key, owned by the current account.
  ///
  /// The upsert conflicts on the full `{box, id, owner}` key, so two accounts
  /// storing the same key keep two rows and neither overwrites the other.
  ///
  /// It also CLAIMS the pre-scoping row for this key when there is one: a row
  /// with no owner is visible to the current account, so leaving it behind
  /// next to the row just written would leave the same key visible twice. This
  /// is the "legacy rows leave the unowned set as they are next written" half
  /// of the rule, and it is not a backfill - only the key actually being
  /// written is touched, by the account actually writing it.
  Future<void> putItem(
    String boxName,
    String key,
    Map<String, dynamic> json,
  ) async {
    final String owner = currentOwner;
    final String encoded = jsonEncode(json);
    await transaction(() async {
      if (owner != kUnownedOwner) {
        await (delete(keyValueTable)..where(
              (t) =>
                  t.box.equals(boxName) &
                  t.id.equals(key) &
                  t.owner.equals(kUnownedOwner),
            ))
            .go();
      }
      await into(keyValueTable).insertOnConflictUpdate(
        KeyValueTableCompanion.insert(
          box: boxName,
          id: key,
          data: encoded,
          owner: Value(owner),
        ),
      );
    });
  }

  /// Get an item as a Map by key, or null when absent.
  ///
  /// Reads the current account's row, falling back to an unowned one. The
  /// explicit `limit(1)` matters: `{box, id}` is no longer unique, so an
  /// unclaimed legacy row and an owned row for the same key can both be
  /// visible, and this must return the owned one rather than throw on two
  /// rows. Ordering by owner descending puts it first - [kUnownedOwner] is the
  /// empty string and sorts below every real owner.
  Future<Map<String, dynamic>?> getItem(String boxName, String key) async {
    final String owner = currentOwner;
    final query = select(keyValueTable)
      ..where(
        (t) =>
            t.box.equals(boxName) &
            t.id.equals(key) &
            ownerVisible(t.owner, owner),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.owner)])
      ..limit(1);
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

  /// Number of items in a box the current account can see, without reading
  /// any of them.
  Future<int> countBox(String boxName) async {
    final count = keyValueTable.id.count();
    final query = selectOnly(keyValueTable)
      ..addColumns([count])
      ..where(
        keyValueTable.box.equals(boxName) &
            ownerVisible(keyValueTable.owner, currentOwner),
      );
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
    final String owner = currentOwner;
    final query = select(keyValueTable)
      ..where((t) {
        final visible =
            t.box.equals(boxName) & ownerVisible(t.owner, owner);
        return afterId == null
            ? visible
            : visible & t.id.isBiggerThanValue(afterId);
      })
      // owner breaks the id tie the wider key made possible (an unclaimed
      // legacy row beside an owned one), so the page order is total.
      ..orderBy([
        (t) => OrderingTerm.asc(t.id),
        (t) => OrderingTerm.desc(t.owner),
      ])
      ..limit(limit);
    return query.get();
  }

  Map<String, dynamic> _decodeRow(KeyValueEntity row) {
    final map = jsonDecode(row.data) as Map<String, dynamic>;
    map.putIfAbsent('id', () => row.id);
    return map;
  }

  /// Delete an item by key - the one the current account can see, which is
  /// its own row and any unowned row for that key. Another account's row for
  /// the same key is left alone.
  Future<void> deleteItem(String boxName, String key) {
    final String owner = currentOwner;
    return (delete(keyValueTable)..where(
          (t) =>
              t.box.equals(boxName) &
              t.id.equals(key) &
              ownerVisible(t.owner, owner),
        ))
        .go();
  }

  /// Clear the items in a box the current account can see. Returns the number
  /// of deleted rows.
  ///
  /// Scoped for the same reason the reads are: this is what an SDK's
  /// session-end hook calls, and before the owner existed it emptied the box
  /// for every account that had ever used the device.
  Future<int> clearBox(String boxName) {
    final String owner = currentOwner;
    return (delete(keyValueTable)..where(
          (t) => t.box.equals(boxName) & ownerVisible(t.owner, owner),
        ))
        .go();
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
