// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
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

import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/sync/sync_engine.dart';

import 'manager_orders_local_store.dart';
import 'order_create_sync_handler.dart';

/// One scanned line of a POS till sale — the product being sold and its
/// DECIMAL quantity (weighed goods sell fractional kg/L).
class PosSaleLine {
  const PosSaleLine({required this.productId, required this.quantity});

  /// Product docname (Frappe hash string).
  final String productId;
  final double quantity;
}

/// Feeds a finished POS till sale into the EXISTING seller create-order
/// pipeline, offline-first (Ray's rulings, 2026-08-28): the sale is
/// written to the local drift store FIRST and the push rides the
/// SyncEngine's `order.create` outbox — checkout NEVER blocks on the
/// network. An online till drains the op moments later through the same
/// [OrderCreateSyncHandler] an offline one uses on reconnect; the
/// backend's `@idempotent` + `offline_uuid` dedupe make retries safe.
///
/// The body is the canonical `create_order(order_data)` contract the
/// backend actually reads (`shop` / `user` / `order_items[].product`),
/// carrying the POS additions honored for seller-origin sessions only:
/// the order's REAL `status` (lowercase wire string — an in-store sale is
/// already 'delivered'; a packed send-for-delivery sale is 'ready' and an
/// offline one HOLDS there until synced) and the credit / partly-paid
/// pair (`payment_status: 'Credit'` + `paid_now`).
class PosSaleQueue {
  PosSaleQueue._();

  /// Builds the `create_order` body for a POS sale. Pure and static so the
  /// contract is unit-testable without a store or engine.
  static Map<String, dynamic> buildOrderBody({
    required String offlineUuid,
    required List<PosSaleLine> lines,
    required String deliveryType,
    required String status,
    double? quotedTotal,
    String? userId,
    String? phone,
    String? address,
    double? paidNow,
    bool onCredit = false,
    String? note,
  }) {
    return {
      'lang': LocalStorage.getLanguage()?.locale,
      'currency': LocalStorage.getSelectedCurrency()?.id,
      'rate': LocalStorage.getSelectedCurrency()?.rate,
      'shop': LocalStorage.getShopJson()?['id']?.toString(),
      'delivery_type': deliveryType,
      'delivery_date': DateTime.now().toIso8601String(),
      'status': status,
      if (userId != null && userId.isNotEmpty) 'user': userId,
      if (phone != null && phone.isNotEmpty)
        'phone': phone.replaceAll('+', ''),
      if (address != null && address.isNotEmpty)
        'address': {'address': address},
      if (quotedTotal != null) 'quoted_total': quotedTotal,
      if (onCredit) 'payment_status': 'Credit',
      if (paidNow != null && (onCredit || paidNow > 0))
        'paid_now': paidNow,
      if (note != null && note.isNotEmpty) 'note': note,
      'order_items': [
        for (final line in lines)
          {'product': line.productId, 'quantity': line.quantity},
      ],
      // The idempotency identity: the till's stable POS order id, so an
      // ambiguous-failure retry (or a duplicate enqueue) can never
      // double-create (backend dedupe, order.py's offline_uuid check).
      'offline_uuid': offlineUuid,
    };
  }

  /// Local-first submit: write-through to [ManagerOrdersLocalStore], then
  /// enqueue the `order.create` op the existing sync handler drains.
  /// Returns the local record id (`offline:<uuid>`); the record gains its
  /// backend id when the engine pushes it.
  static Future<String> queueSale({
    required String offlineUuid,
    required List<PosSaleLine> lines,
    required String deliveryType,
    required String status,
    double? quotedTotal,
    String? userId,
    String? phone,
    String? address,
    double? paidNow,
    bool onCredit = false,
    String? note,
  }) async {
    final order = buildOrderBody(
      offlineUuid: offlineUuid,
      lines: lines,
      deliveryType: deliveryType,
      status: status,
      quotedTotal: quotedTotal,
      userId: userId,
      phone: phone,
      address: address,
      paidNow: paidNow,
      onCredit: onCredit,
      note: note,
    );
    final String localId = SyncEngine.newTempId();
    await ManagerOrdersLocalStore.putPending(localId, {'order': order});
    // Same parent-op wiring as SellerOrdersRepository.createOrder: any
    // offline-created entities the body references make their minting
    // ops this op's parents, so creates land in order with real ids
    // substituted in.
    final dependsOn = await ManagerOrdersLocalStore.pendingOpIdsCreating(
      ManagerOrdersLocalStore.offlineTokensIn(jsonEncode(order)),
    );
    await SyncEngine().enqueue(
      opType: OrderCreateSyncHandler.opType,
      sdk: OrderCreateSyncHandler.sdkName,
      payload: {'localId': localId, 'order': order},
      tempIds: [localId],
      dependsOn: dependsOn,
    );
    return localId;
  }

  /// POS sales not yet reconciled with the backend — the till's
  /// pending-sync surface (billing page indicator).
  static Future<int> pendingCount() async =>
      (await ManagerOrdersLocalStore.unsynced()).length;
}
