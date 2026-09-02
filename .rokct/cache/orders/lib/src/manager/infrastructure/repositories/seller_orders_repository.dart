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

import 'package:flutter/material.dart';
import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/models/data/location.dart';
import 'package:base_sdk/src/models/response/transactions_response.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/sync/sync_engine.dart';
import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';
import 'package:orders_sdk/src/manager/infrastructure/services/manager_orders_local_store.dart';
import 'package:orders_sdk/src/manager/infrastructure/services/collect_conversion_sync_handler.dart';
import 'package:orders_sdk/src/manager/infrastructure/services/order_create_sync_handler.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/collect_conversion.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/order_calculate_data.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/stock.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/user_data.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/response/create_order_response.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/response/order_status_response.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/response/orders_paginate_response.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/response/payments_response.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/response/single_order_response.dart';

/// Port of `paas_manager`'s `OrdersRepository`, repointed from the legacy
/// `/api/v1/dashboard/seller/...` paths to `seller_order.py` in the merchants
/// Frappe app where a counterpart exists. Where none exists yet the legacy
/// contract is still declared and called — see
/// `docs/frappe-endpoint-contract.md` for the endpoint-by-endpoint state; an
/// unanswered call fails through [ApiResult.failure] rather than being faked.
const _base = '/api/method/paas.api.seller_order.seller_order';

class SellerOrdersRepository implements SellerOrdersRepositoryFacade {
  /// Universal platform gateway (fleet rule 2026-08-15): cmds mirror the
  /// owning modules' `manifest.json` whitelisted-method keys with the app
  /// segment dropped.
  static const _gateway = PlatformGateway();

  /// The wire strings are the legacy ones; base_sdk's `OrderStatus.open` is
  /// the manager fork's old `newOrder` ('new'), `onWay` is 'on_a_way'.
  String? _statusText(OrderStatus? status) {
    switch (status) {
      case OrderStatus.open:
        return 'new';
      case OrderStatus.accepted:
        return 'accepted';
      case OrderStatus.ready:
        return 'ready';
      case OrderStatus.onWay:
        return 'on_a_way';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.canceled:
        return 'canceled';
      default:
        return null;
    }
  }

  ApiResult<T> _fail<T>(Object e, String label) {
    debugPrint('==> $label failure: $e');
    return ApiResult.failure(
      error: AppHelpers.errorHandler(e),
      statusCode: NetworkExceptions.getDioStatus(e),
    );
  }

  @override
  Future<ApiResult<OrdersPaginateResponse>> getOrders({
    OrderStatus? status,
    String? rawStatus,
    int? page,
    String? from,
    String? to,
  }) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '$_base.get_seller_orders',
        queryParameters: {
          if (page != null) 'limit_start': (page - 1) * 10,
          'limit_page_length': 10,
          if (rawStatus != null)
            'status': rawStatus
          else if (status != null)
            'status': _statusText(status),
          if (from != null) 'from_date': from,
          if (to != null) 'to_date': to,
          'lang': LocalStorage.getLanguage()?.locale,
        },
      );
      return ApiResult.success(
        data: OrdersPaginateResponse.fromJson(response.data),
      );
    } catch (e) {
      return _fail(e, 'get seller orders $status');
    }
  }

  @override
  Future<ApiResult<OrdersPaginateResponse>> getHistoryOrders({
    int? page,
    String? from,
    String? to,
  }) async {
    // No dedicated history endpoint: the legacy call was the same paginate
    // with statuses[delivered,canceled]. get_seller_orders takes one status,
    // so history is fetched as 'delivered' and the canceled bucket is part of
    // the recorded endpoint gap (statuses[] filter).
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '$_base.get_seller_orders',
        queryParameters: {
          if (page != null) 'limit_start': (page - 1) * 10,
          'limit_page_length': 10,
          'status': 'delivered',
          if (from != null) 'from_date': from,
          if (to != null) 'to_date': to,
          'lang': LocalStorage.getLanguage()?.locale,
        },
      );
      return ApiResult.success(
        data: OrdersPaginateResponse.fromJson(response.data),
      );
    } catch (e) {
      return _fail(e, 'get seller history orders');
    }
  }

  @override
  Future<ApiResult<SingleOrderResponse>> getOrderDetails({
    required String orderId,
  }) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '$_base.get_seller_order_details',
        queryParameters: {
          'order_id': orderId,
          'lang': LocalStorage.getLanguage()?.locale,
        },
      );
      return ApiResult.success(
        data: SingleOrderResponse.fromJson(response.data),
      );
    } catch (e) {
      return _fail(e, 'get seller order details');
    }
  }

  @override
  Future<ApiResult<OrderStatusResponse>> updateOrderStatus({
    OrderStatus? status,
    String? rawStatus,
    required String orderId,
  }) async {
    assert(status != null || rawStatus != null,
        'updateOrderStatus needs a status or a rawStatus');
    final data = {
      'order_id': orderId,
      'status': rawStatus ?? _statusText(status),
    };
    debugPrint('===> update order status request ${jsonEncode(data)}');
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.post(
        '$_base.update_seller_order_status',
        data: data,
      );
      return ApiResult.success(
        data: OrderStatusResponse.fromJson(response.data),
      );
    } catch (e) {
      return _fail(e, 'update seller order status');
    }
  }

  @override
  Future<ApiResult<CollectConversion>> convertDeliveryToCollected({
    required String orderId,
  }) async {
    // ONE call. The conversion flips the delivery type, stands the driver
    // down, settles the fee (back to her wallet, or to him as a callout)
    // and completes the order — all inside one server transaction, in an
    // order that matters: the driver is unassigned BEFORE the order
    // reaches Delivered, or the settlement pays him the fee a second
    // time. Orchestrating that from here would leave half-converted
    // orders behind every dropped connection.
    try {
      final response = await _gateway.call(
        'api.seller_order.convert_delivery_to_collected',
        payload: {'order_id': orderId},
      );
      return ApiResult.success(
        data: CollectConversion.fromJson(
          (response as Map).cast<String, dynamic>(),
        ),
      );
    } catch (e) {
      final status = NetworkExceptions.getDioStatus(e);
      if (status >= 400 && status < 500 && status != 408) {
        // Backend reachable and said no (not a delivery order, not this
        // shop's, already delivered): a real refusal, surfaced as one.
        return _fail(e, 'convert delivery order to collected');
      }
      // Backend unreachable / transient. The goods are already going
      // over the counter — that never waits on a network — so the
      // conversion is queued and reported as DEFERRED. Nothing is
      // claimed about the fee: which branch applies is server state.
      await SyncEngine().enqueue(
        opType: CollectConversionSyncHandler.opType,
        sdk: CollectConversionSyncHandler.sdkName,
        payload: {'order_id': orderId},
      );
      return const ApiResult.success(data: CollectConversion.deferred());
    }
  }

  @override
  Future<ApiResult<CreateOrderResponse>> createOrder({
    required String deliveryType,
    required List<Stock> stocks,
    required String deliveryTime,
    required String address,
    UserData? user,
    LocationModel? location,
    String? entrance,
    String? tableId,
    String? floor,
    String? house,
    String? paymentId,
  }) async {
    // Body shape is the legacy seller create-order contract, byte for byte —
    // the POS depends on it. The wrapping `order_data` argument matches
    // orders' `create_order(order_data)` (gateway cmd
    // `api.order.create_order`); the seller-scoped variant is a recorded
    // endpoint gap.
    List<Map<String, dynamic>> products = [];
    for (final stock in stocks) {
      List<Map<String, dynamic>> addons = [];
      for (AddonData addon
          in stock.addons?.where((e) => e.active ?? false) ?? []) {
        addons.add({
          'stock_id': addon.product?.stock?.id,
          'quantity': addon.quantity ?? 1,
        });
      }
      products.add({
        'stock_id': stock.id,
        'quantity': stock.quantity ?? 1,
        if (addons.isNotEmpty) 'addons': addons,
        if (stock.bonus ?? false) 'bonus': true,
        if (stock.shopBonus ?? false) 'bonus_shop': true,
      });
    }
    final order = {
      'lang': LocalStorage.getLanguage()?.locale,
      'currency_id': LocalStorage.getSelectedCurrency()?.id,
      'rate': LocalStorage.getSelectedCurrency()?.rate,
      'shop_id': LocalStorage.getShopJson()?['id'],
      if (user?.phone != null) 'phone': user?.phone?.replaceAll('+', ''),
      'delivery_type': deliveryType,
      if (user?.id != null) 'user_id': user?.id,
      'products': products,
      if (tableId != null) 'table_id': tableId,
      'delivery_date': deliveryTime,
      if (address.isNotEmpty)
        'address': {
          'address': address,
          if (entrance != null) 'office': entrance,
          if (house != null) 'house': house,
          if (floor != null) 'floor': floor,
        },
      if (location != null)
        'location': {
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
    };
    debugPrint('===> create order body ${jsonEncode(order)}');
    // Local-first: write the record through before the network attempt so a
    // dead connection can never lose the sale.
    final String localId = SyncEngine.newTempId();
    await ManagerOrdersLocalStore.putPending(localId, {
      'order': order,
      if (paymentId != null) 'payment_id': paymentId,
    });
    try {
      final response = await _gateway.tenant(
        'api.order.create_order',
        {'order_data': order},
      );
      // Backend reachable and accepted: it is authoritative from here on
      // (the order queues refetch supplies the row), so the write-through
      // record goes.
      await ManagerOrdersLocalStore.delete(localId);
      return ApiResult.success(
        data: CreateOrderResponse.fromJson(response),
      );
    } catch (e) {
      final status = NetworkExceptions.getDioStatus(e);
      if (status >= 400 && status < 500 && status != 408) {
        // Backend reachable and said no — unchanged backend-first behavior;
        // the local record must not survive a definitive rejection.
        await ManagerOrdersLocalStore.delete(localId);
        return _fail(e, 'create seller order');
      }
      // Backend unreachable / transient: keep the record, queue the push and
      // report success (getDioStatus maps connection failures and timeouts
      // to 500). Any offline-created entities the body references (temp
      // shop, temp products) make their minting ops this op's parents, so
      // creates land in order with real ids substituted in.
      final dependsOn = await ManagerOrdersLocalStore.pendingOpIdsCreating(
        ManagerOrdersLocalStore.offlineTokensIn(jsonEncode(order)),
      );
      await SyncEngine().enqueue(
        opType: OrderCreateSyncHandler.opType,
        sdk: OrderCreateSyncHandler.sdkName,
        payload: {
          'localId': localId,
          'order': order,
          if (paymentId != null) 'payment_id': paymentId,
        },
        tempIds: [localId],
        dependsOn: dependsOn,
      );
      return ApiResult.success(data: CreateOrderResponse(localId: localId));
    }
  }

  @override
  Future<ApiResult<TransactionsResponse>> createTransaction({
    required String orderId,
    required String paymentId,
  }) async {
    // Frappe counterpart of POST /api/v1/payments/order/{id}/transactions:
    // pay-side wallet/frappe/src/api/payment/payment.py's
    // create_order_transaction (idempotent; dedupes per order + gateway,
    // amount/user read from the Order doc server-side).
    final data = {'order_id': orderId, 'payment_sys_id': paymentId};
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.post(
        '/api/method/paas.api.payment.create_order_transaction',
        data: data,
      );
      return ApiResult.success(
        data: TransactionsResponse.fromJson(response.data),
      );
    } catch (e) {
      return _fail(e, 'create transaction');
    }
  }

  @override
  Future<ApiResult<PaymentsResponse>> getPayments() async {
    // Frappe counterpart of GET /api/v1/dashboard/seller/shop-payments:
    // merchants' seller_transactions.get_seller_shop_payments, via the
    // universal platform gateway.
    try {
      final response =
          await _gateway.tenant('api.seller_transactions.get_seller_shop_payments');
      return ApiResult.success(data: PaymentsResponse.fromJson(response));
    } catch (e) {
      return _fail(e, 'get seller payments');
    }
  }

  @override
  Future<ApiResult<OrderCalculate>> getCalculate({
    required List<Stock> stocks,
    required String type,
    LocationModel? location,
  }) async {
    // Recorded gap (FORK_MAPPING §3 Ask #6): paas.api.order.order.get_calculate
    // is cart-id based; the seller POS needs this stock-list shape. Legacy
    // query contract preserved verbatim.
    final data = <String, dynamic>{
      'currency_id': LocalStorage.getSelectedCurrency()?.id,
      'shop_id': LocalStorage.getShopJson()?['id'],
      'type': type,
      if (location != null) 'address[latitude]': location.latitude,
      if (location != null) 'address[longitude]': location.longitude,
    };
    for (int i = 0; i < stocks.length; i++) {
      data['products[$i][stock_id]'] = stocks[i].id;
      data['products[$i][quantity]'] = stocks[i].cartCount ?? 1;
      final addons =
          stocks[i].addons?.where((e) => e.active ?? false).toList() ?? [];
      for (int j = 0; j < addons.length; j++) {
        data['products[$i][addons][$j][stock_id]'] =
            addons[j].product?.stock?.id;
        data['products[$i][addons][$j][quantity]'] = addons[j].quantity ?? 1;
      }
    }
    debugPrint('==> order calculate request: ${jsonEncode(data)}');
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/method/paas.api.order.order.get_products_calculate',
        queryParameters: data,
      );
      return ApiResult.success(data: OrderCalculate.fromJson(response.data));
    } catch (e) {
      return _fail(e, 'get seller order calculate');
    }
  }
}
