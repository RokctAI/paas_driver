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

// A queued POS sale for a shop still pending approval (orders_sdk 1.30.0):
// create_order's SHOP_PENDING_APPROVAL refusal holds the sale instead of
// parking it, and the sale syncs in the status it is in by then, since
// staff may have moved it on the board while it waited.

import 'dart:convert';
import 'dart:typed_data';

import 'package:base_sdk/src/database/app_database.dart';
import 'package:base_sdk/src/handlers/http_service.dart';
import 'package:base_sdk/src/sync/sync_handler.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:orders_sdk/src/manager/infrastructure/services/manager_orders_local_store.dart';
import 'package:orders_sdk/src/manager/infrastructure/services/order_create_sync_handler.dart';

/// Answers every gateway call with [status] and [body], recording payloads.
class _ScriptedHttp extends HttpService {
  int status = 200;
  Object body = const <String, dynamic>{};
  final List<Map<String, dynamic>> payloads = <Map<String, dynamic>>[];

  @override
  Dio client({bool requireAuth = false, bool routing = false}) =>
      Dio(BaseOptions(baseUrl: 'https://gateway.test'))
        ..httpClientAdapter = _Adapter(this)
        ..interceptors.add(const FrappeResponseInterceptor());
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.owner);

  final _ScriptedHttp owner;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final data = options.data;
    if (data is Map) {
      owner.payloads.add(
        (data['payload'] as Map? ?? const {}).cast<String, dynamic>(),
      );
    }
    return ResponseBody.fromString(
      jsonEncode(owner.body),
      owner.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const String _localId = 'offline:6f1c2a9e-0000-4000-8000-000000000001';

OutboxEntry _op() => OutboxEntry(
      id: 'op-1',
      owner: 'seller@example.com',
      opType: OrderCreateSyncHandler.opType,
      sdk: OrderCreateSyncHandler.sdkName,
      payload: jsonEncode({
        'localId': _localId,
        'order': {'shop': 'SHOP-1', 'status': 'new'},
      }),
      tempIds: '[]',
      dependsOn: '[]',
      status: 'pending',
      attempts: 0,
      createdAt: DateTime(2026, 10, 12),
      updatedAt: DateTime(2026, 10, 12),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late _ScriptedHttp http;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    AppDatabase.debugOverrideInstance(db);
    http = _ScriptedHttp();
    if (GetIt.I.isRegistered<HttpService>()) {
      GetIt.I.unregister<HttpService>();
    }
    GetIt.I.registerSingleton<HttpService>(http);
    await ManagerOrdersLocalStore.putPending(_localId, {
      'order': {'shop': 'SHOP-1', 'status': 'new'},
    });
  });

  tearDown(() async {
    AppDatabase.debugOverrideInstance(null);
    await db.close();
  });

  test('a shop pending approval holds the sale, it is not parked', () async {
    http
      ..status = 423
      ..body = {
        'exc_type': 'ShopPendingApproval',
        'exception': 'SHOP_PENDING_APPROVAL: this shop is waiting for '
            'approval.',
      };

    final result = await OrderCreateSyncHandler().push(_op());

    expect(result, isA<SyncHeld>());
    final record = (await ManagerOrdersLocalStore.get(_localId))!;
    expect(record['needs_attention'], isFalse);
    expect(record['pending_sync'], isTrue);
    expect(record['synced'], isFalse);
  });

  test('the marker alone is enough when the status code is lost', () {
    expect(
      OrderCreateSyncHandler.isShopPendingApproval(
        Exception('x'),
        status: 417,
        message: 'SHOP_PENDING_APPROVAL: this shop is waiting for approval.',
      ),
      isTrue,
    );
    expect(
      OrderCreateSyncHandler.isShopPendingApproval(
        Exception('x'),
        status: 417,
        message: 'Insufficient stock',
      ),
      isFalse,
    );
  });

  test('a queued sale moved on the board syncs in its new status', () async {
    expect(
      await ManagerOrdersLocalStore.setLocalStatus(_localId, 'delivered'),
      isTrue,
    );
    final rows = await ManagerOrdersLocalStore.unsyncedAsOrders(
      status: 'delivered',
    );
    expect(rows.map((o) => o.localId), [_localId]);
    expect(
      await ManagerOrdersLocalStore.unsyncedAsOrders(status: 'new'),
      isEmpty,
    );

    http.body = {
      'message': {
        'data': {'id': 'ORD-1'},
      },
    };
    final result = await OrderCreateSyncHandler().push(_op());

    expect(result, isA<SyncSynced>());
    final orderData =
        (http.payloads.first['order_data'] as Map).cast<String, dynamic>();
    expect(orderData['status'], 'delivered');
  });

  test('a synced sale no longer moves locally', () async {
    await ManagerOrdersLocalStore.markSynced(_localId, backendId: 'ORD-1');
    expect(
      await ManagerOrdersLocalStore.setLocalStatus(_localId, 'ready'),
      isFalse,
    );
  });
}
