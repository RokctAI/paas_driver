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

import 'dart:async';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:base_sdk/src/database/app_database.dart';
import 'package:base_sdk/src/sync/outbox_table.dart';
import 'package:base_sdk/src/sync/plan_sync_gate.dart';
import 'package:base_sdk/src/sync/sync_engine.dart';
import 'package:base_sdk/src/sync/sync_handler.dart';

class _Counting extends SyncHandler {
  int pushed = 0;

  @override
  Future<SyncResult> push(OutboxEntry op) async {
    pushed++;
    return const SyncResult.synced();
  }
}

/// The free local-only tier: a closed gate keeps ops pending and untouched,
/// an open one drains, and with no gate set the engine is unchanged.
void main() {
  late AppDatabase db;
  late SyncEngine engine;
  late _Counting handler;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    AppDatabase.debugOverrideInstance(db);
    SyncEngine.debugReset();
    engine = SyncEngine();
    handler = _Counting();
    engine.registerHandler('demo.op', handler);
    await engine.enqueue(
      id: 'op-1',
      opType: 'demo.op',
      sdk: 'test_sdk',
      payload: const <String, dynamic>{},
    );
  });

  tearDown(() async {
    SyncEngine.debugReset();
    AppDatabase.debugOverrideInstance(null);
    try {
      await db.close();
    } catch (_) {}
  });

  Future<List<OutboxEntry>> rows() => db.select(db.outboxTable).get();

  test('no gate set: drains as before', () async {
    await engine.kick();
    expect(handler.pushed, 1);
    expect(await rows(), isEmpty);
  });

  test('closed gate: nothing pushed, op stays pending with no retries spent',
      () async {
    engine.pushGate = () async => false;
    await engine.kick();
    expect(handler.pushed, 0);
    final left = await rows();
    expect(left, hasLength(1));
    expect(left.single.status, OutboxStatus.pending.name);
    expect(left.single.attempts, 0);
  });

  test('a throwing gate keeps the data local', () async {
    engine.pushGate = () async => throw StateError('boom');
    await engine.kick();
    expect(handler.pushed, 0);
    expect(await rows(), hasLength(1));
  });

  test('gate opening later drains the backlog', () async {
    var open = false;
    engine.pushGate = () async => open;
    await engine.kick();
    expect(handler.pushed, 0);
    open = true;
    await engine.kick();
    expect(handler.pushed, 1);
    expect(await rows(), isEmpty);
  });

  group('PlanSyncGate', () {
    PlanSyncGate gate({
      required Future<dynamic> Function() fetch,
      bool? cached,
      List<bool>? written,
    }) =>
        PlanSyncGate(
          fetch: fetch,
          readCache: () async => cached,
          writeCache: (v) async => written?.add(v),
        );

    test('backend allows: true and cached', () async {
      final written = <bool>[];
      final g = gate(
        fetch: () async => {
          'message': {'sync_allowed': true},
        },
        written: written,
      );
      expect(await g.allowsPush(), isTrue);
      expect(written, <bool>[true]);
    });

    test('backend says plan required: false', () async {
      final g = gate(
        fetch: () async => {'sync_allowed': false, 'reason': 'plan_required'},
        cached: true,
      );
      expect(await g.allowsPush(), isFalse);
    });

    test('offline uses the cached answer', () async {
      final g = gate(fetch: () async => throw Exception('offline'), cached: true);
      expect(await g.allowsPush(), isTrue);
    });

    test('offline with no cache keeps the data local', () async {
      final g = gate(fetch: () async => throw Exception('offline'));
      expect(await g.allowsPush(), isFalse);
    });

    test('a hanging backend falls back to the cached answer after the timeout',
        () async {
      final g = PlanSyncGate(
        fetch: () => Completer<dynamic>().future,
        readCache: () async => true,
        writeCache: (_) async {},
        fetchTimeout: const Duration(milliseconds: 20),
      );
      expect(await g.allowsPush(), isTrue);
    });

    test('a hanging backend with no cache keeps the data local', () async {
      final g = PlanSyncGate(
        fetch: () => Completer<dynamic>().future,
        readCache: () async => null,
        writeCache: (_) async {},
        fetchTimeout: const Duration(milliseconds: 20),
      );
      expect(await g.allowsPush(), isFalse);
    });

    test('install wires the gate onto the engine', () async {
      gate(fetch: () async => {'sync_allowed': false}).install(engine);
      await engine.kick();
      expect(handler.pushed, 0);
    });

    test('PlanAccess follows the answer and is visible by default', () async {
      PlanAccess.planGatedVisible.value = true;
      await gate(fetch: () async => {'sync_allowed': false}).allowsPush();
      expect(PlanAccess.planGatedVisible.value, isFalse);
      await gate(fetch: () async => {'sync_allowed': true}).allowsPush();
      expect(PlanAccess.planGatedVisible.value, isTrue);
    });

    test('PlanAccess hides on a failed fetch with no cache', () async {
      PlanAccess.planGatedVisible.value = true;
      final g = PlanSyncGate(
        fetch: () async => throw Exception('offline'),
        readCache: () async => null,
        writeCache: (_) async {},
      );
      await g.allowsPush();
      expect(PlanAccess.planGatedVisible.value, isFalse);
    });

    test('declared sections are hidden only while the plan flag is false', () {
      PlanAccess.reset();
      PlanAccess.gateProfileSections(['a.tasks']);
      expect(PlanAccess.isSectionHidden('a.tasks'), isFalse);
      PlanAccess.planGatedVisible.value = false;
      expect(PlanAccess.isSectionHidden('a.tasks'), isTrue);
      expect(PlanAccess.isSectionHidden('other'), isFalse);
      PlanAccess.reset();
    });
  });
}
