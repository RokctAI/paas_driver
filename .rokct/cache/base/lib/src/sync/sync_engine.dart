import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import 'package:base_sdk/src/database/app_database.dart';
import 'package:base_sdk/src/sync/outbox_table.dart';
import 'package:base_sdk/src/sync/sync_handler.dart';

/// Prefix marking a locally minted id, shared with auth's offline-token
/// convention (`OfflineAuthService.isOfflineToken`).
const String kOfflineIdPrefix = 'offline:';

/// Drains the offline outbox to the backend.
///
/// Process-wide singleton like [AppDatabase]. Feature SDKs register a
/// [SyncHandler] per op type; base triggers [kick] at boot (splash online
/// path) and on connectivity regain (`ConnectivityService`). With no
/// handlers registered and an empty outbox the engine is inert — [kick]
/// reads one empty table and returns.
class SyncEngine {
  SyncEngine._internal();

  factory SyncEngine() => _instance ??= SyncEngine._internal();
  static SyncEngine? _instance;

  /// Retry delays indexed by (attempts - 1); the last entry repeats until
  /// [maxAttempts] is reached.
  static const List<Duration> backoff = [
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 30),
    Duration(hours: 6),
  ];

  /// Retryable failures beyond this mark the op [OutboxStatus.dead].
  static const int maxAttempts = 10;

  final Map<String, SyncHandler> _handlers = {};

  bool _draining = false;
  bool _kickRequested = false;

  AppDatabase get _db => AppDatabase();

  /// Route ops of [opType] to [handler]. Re-registering replaces the
  /// previous handler (hot-restart safe).
  void registerHandler(String opType, SyncHandler handler) {
    _handlers[opType] = handler;
  }

  /// New outbox op id / idempotency key.
  static String newOpId() => _uuidV4();

  /// New temp entity id in the shared `offline:<uuid>` convention.
  static String newTempId() => '$kOfflineIdPrefix${_uuidV4()}';

  /// Queue an op for push. Returns the outbox id (also the idempotency key).
  ///
  /// Does not push by itself — call [kick] afterwards when the op should go
  /// out immediately (the boot and connectivity triggers cover the rest).
  Future<String> enqueue({
    required String opType,
    required String sdk,
    required Map<String, dynamic> payload,
    List<String> tempIds = const [],
    List<String> dependsOn = const [],
    String? id,
  }) async {
    final now = DateTime.now();
    final opId = id ?? newOpId();
    await _db
        .into(_db.outboxTable)
        .insert(
          OutboxTableCompanion.insert(
            id: opId,
            opType: opType,
            sdk: sdk,
            payload: jsonEncode(payload),
            tempIds: jsonEncode(tempIds),
            dependsOn: jsonEncode(dependsOn),
            status: OutboxStatus.pending.name,
            attempts: 0,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return opId;
  }

  /// Queue a coalescing op: at most one outbox row per (opType, dedupeKey),
  /// under the deterministic id `<opType>:<dedupeKey>`. While that row is
  /// still in the outbox, calling again replaces its payload with the newer
  /// one and resets it to pending (latest snapshot wins) — including when
  /// the old payload is mid-push, in which case the row survives that push
  /// and goes out again with the new payload. Use for ops whose payload is
  /// a full snapshot (e.g. `cart.sync`), where replaying every intermediate
  /// state would be wasteful.
  Future<String> enqueueOrReplace({
    required String opType,
    required String sdk,
    required String dedupeKey,
    required Map<String, dynamic> payload,
    List<String> tempIds = const [],
    List<String> dependsOn = const [],
  }) async {
    final opId = '$opType:$dedupeKey';
    final existing = await (_db.select(
      _db.outboxTable,
    )..where((t) => t.id.equals(opId))).getSingleOrNull();
    if (existing == null) {
      return enqueue(
        opType: opType,
        sdk: sdk,
        payload: payload,
        tempIds: tempIds,
        dependsOn: dependsOn,
        id: opId,
      );
    }
    // Fresh snapshot: earlier failures no longer apply, so retry state is
    // reset alongside the payload.
    await _writeOp(
      opId,
      OutboxTableCompanion(
        payload: Value(jsonEncode(payload)),
        tempIds: Value(jsonEncode(tempIds)),
        dependsOn: Value(jsonEncode(dependsOn)),
        status: Value(OutboxStatus.pending.name),
        attempts: const Value(0),
        lastError: const Value(null),
        nextAttemptAt: const Value(null),
      ),
    );
    return opId;
  }

  /// Whether any op of [opType] is still in the outbox, whatever its
  /// status — a failed or dead op also means the backend has not caught up.
  Future<bool> hasPending(String opType) async {
    final row = await (_db.select(_db.outboxTable)
          ..where((t) => t.opType.equals(opType))
          ..limit(1))
        .get();
    return row.isNotEmpty;
  }

  /// Drain pending ops oldest-first. Safe to call from anywhere at any
  /// time: overlapping calls coalesce into one extra pass, ops without a
  /// registered handler stay pending untouched, and backoff windows are
  /// respected.
  Future<void> kick() async {
    if (_draining) {
      // A drain is running; have it take one more pass so ops enqueued
      // since it started are not missed.
      _kickRequested = true;
      return;
    }
    _draining = true;
    try {
      do {
        _kickRequested = false;
        await _drainOnce();
      } while (_kickRequested);
    } finally {
      _draining = false;
    }
  }

  Future<void> _drainOnce() async {
    final now = DateTime.now();
    final pending =
        await (_db.select(_db.outboxTable)
              ..where((t) => t.status.equals(OutboxStatus.pending.name))
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();
    if (pending.isEmpty) return;

    // A dependency is satisfied once its row is gone from the outbox
    // (synced ops are deleted); any id still present — whatever its
    // status — blocks the dependent op.
    final unsynced = (await _db.select(_db.outboxTable).get())
        .map((op) => op.id)
        .toSet();

    for (final op in pending) {
      if (op.nextAttemptAt != null && op.nextAttemptAt!.isAfter(now)) {
        continue; // Still backing off.
      }
      final blocked = _decodeStringList(
        op.dependsOn,
      ).any((depId) => depId != op.id && unsynced.contains(depId));
      if (blocked) continue; // Parents before children.
      final handler = _handlers[op.opType];
      if (handler == null) continue; // Owning SDK not composed/registered.

      await _setStatus(op.id, OutboxStatus.inFlight);
      SyncResult result;
      try {
        result = await handler.push(op);
      } catch (e) {
        result = SyncResult.retryable(e.toString());
      }
      switch (result) {
        case SyncSynced(:final idMappings, :final entityType):
          final removed = await _applySynced(op, handler, idMappings, entityType);
          if (removed) unsynced.remove(op.id);
        case SyncRetryable(:final error):
          await _applyRetryable(op, error);
        case SyncRejected(:final error):
          await _applyRejected(op, error);
      }
    }
  }

  /// Returns whether the op's row was actually removed from the outbox.
  Future<bool> _applySynced(
    OutboxEntry op,
    SyncHandler handler,
    Map<String, String> idMappings,
    String? entityType,
  ) async {
    final now = DateTime.now();
    if (idMappings.isNotEmpty) {
      final type = entityType ?? op.opType.split('.').first;
      for (final entry in idMappings.entries) {
        await _db
            .into(_db.idMappingsTable)
            .insertOnConflictUpdate(
              IdMappingsTableCompanion.insert(
                tempId: entry.key,
                backendId: entry.value,
                entityType: type,
                mappedAt: now,
              ),
            );
      }
      await _rewritePendingPayloads(idMappings);
    }
    try {
      await handler.onSynced(op, idMappings);
    } catch (e) {
      // The op itself synced; a callback failure must not re-queue it.
      debugPrint('==> sync onSynced callback failed (${op.opType}): $e');
    }
    // Delete only while still inFlight: enqueueOrReplace may have swapped in
    // a newer payload mid-push (resetting the row to pending), and that
    // newer snapshot must survive to be pushed on the next pass.
    final deleted = await (_db.delete(_db.outboxTable)..where(
          (t) =>
              t.id.equals(op.id) &
              t.status.equals(OutboxStatus.inFlight.name),
        ))
        .go();
    return deleted > 0;
  }

  /// Exact-string substitution of `offline:<uuid>` tokens in still-pending
  /// payloads. Sound because temp ids are globally unique prefixed strings
  /// that cannot occur naturally in payload JSON.
  Future<void> _rewritePendingPayloads(Map<String, String> idMappings) async {
    final rows = await (_db.select(
      _db.outboxTable,
    )..where((t) => t.status.equals(OutboxStatus.pending.name))).get();
    for (final row in rows) {
      var payload = row.payload;
      idMappings.forEach((tempId, backendId) {
        payload = payload.replaceAll(tempId, backendId);
      });
      if (payload == row.payload) continue;
      await (_db.update(
        _db.outboxTable,
      )..where((t) => t.id.equals(row.id))).write(
        OutboxTableCompanion(
          payload: Value(payload),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<void> _applyRetryable(OutboxEntry op, String error) async {
    final attempts = op.attempts + 1;
    if (attempts >= maxAttempts) {
      await _writeOp(
        op.id,
        OutboxTableCompanion(
          status: Value(OutboxStatus.dead.name),
          attempts: Value(attempts),
          lastError: Value(error),
        ),
      );
      return;
    }
    final delay = backoff[math.min(attempts - 1, backoff.length - 1)];
    await _writeOp(
      op.id,
      OutboxTableCompanion(
        status: Value(OutboxStatus.pending.name),
        attempts: Value(attempts),
        lastError: Value(error),
        nextAttemptAt: Value(DateTime.now().add(delay)),
      ),
    );
  }

  Future<void> _applyRejected(OutboxEntry op, String error) async {
    await _writeOp(
      op.id,
      OutboxTableCompanion(
        status: Value(OutboxStatus.failed.name),
        attempts: Value(op.attempts + 1),
        lastError: Value(error),
      ),
    );
  }

  Future<void> _setStatus(String id, OutboxStatus status) =>
      _writeOp(id, OutboxTableCompanion(status: Value(status.name)));

  Future<void> _writeOp(String id, OutboxTableCompanion changes) async {
    await (_db.update(_db.outboxTable)..where((t) => t.id.equals(id))).write(
      changes.copyWith(updatedAt: Value(DateTime.now())),
    );
  }

  List<String> _decodeStringList(String json) {
    try {
      return (jsonDecode(json) as List).cast<String>();
    } catch (_) {
      return const [];
    }
  }
}

final math.Random _random = math.Random.secure();

/// RFC 4122 version 4 UUID from a cryptographically secure source (no
/// package dependency needed for just this).
String _uuidV4() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10xx
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}
