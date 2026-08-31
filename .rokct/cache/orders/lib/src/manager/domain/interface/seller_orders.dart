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

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/models/data/location.dart';
import 'package:base_sdk/src/models/response/transactions_response.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/collect_conversion.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/order_calculate_data.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/stock.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/user_data.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/response/create_order_response.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/response/order_status_response.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/response/orders_paginate_response.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/response/payments_response.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/response/single_order_response.dart';

/// Contract of `paas_manager`'s `OrdersInterface`, minus nothing: the manager
/// order queues, order details, POS checkout and history all go through here.
///
/// Owned and implemented by orders_sdk itself ([SellerOrdersRepository]) —
/// unlike the sections/tables and customer seams, this is order data, so no
/// host adapter is involved. `OrderStatus` is base_sdk's enum; the legacy
/// manager members map `newOrder` -> `open` and `onAWay` -> `onWay` (wire
/// strings are unchanged: 'new' / 'on_a_way').
///
/// Payments note: `getPayments`/`createTransaction` ride here for now because
/// they are order-scoped in every call site (POS checkout). If payments_sdk
/// grows a seller-side facade, these two are the seam to move.
abstract class SellerOrdersRepositoryFacade {
  /// [rawStatus] carries a wire status base_sdk's [OrderStatus] cannot
  /// express (the board's `cooking` column); when both are passed,
  /// [rawStatus] wins.
  Future<ApiResult<OrdersPaginateResponse>> getOrders({
    OrderStatus? status,
    String? rawStatus,
    int? page,
    String? from,
    String? to,
  });

  Future<ApiResult<OrdersPaginateResponse>> getHistoryOrders({
    int? page,
    String? from,
    String? to,
  });

  /// [orderId] is the Order docname (Frappe hash string, e.g. `a1b2c3d4e5`)
  /// — never a numeric id; callers must abort (with a debug log) instead of
  /// passing a sentinel when no id is available.
  Future<ApiResult<SingleOrderResponse>> getOrderDetails({
    required String orderId,
  });

  /// Pass exactly one of [status] / [rawStatus] ([rawStatus] exists for
  /// the board's `cooking` transition, which [OrderStatus] cannot express;
  /// it wins when both are passed).
  Future<ApiResult<OrderStatusResponse>> updateOrderStatus({
    OrderStatus? status,
    String? rawStatus,
    required String orderId,
  });

  /// The customer turned up and collected an order she had placed for
  /// DELIVERY (design strip section 43). ONE atomic seller call, never a
  /// client-orchestrated sequence: the whole conversion — delivery type,
  /// driver assignment, the fee's fate and the hand-over — lands or none
  /// of it does.
  ///
  /// Offline the branch is undecidable (driver assignment and wallet
  /// balance are both server state), so the goods still go over the
  /// counter and the conversion is QUEUED: the returned
  /// [CollectConversion] carries `deferred` and promises nothing about
  /// the money. A conversion the backend later refuses parks in Sync
  /// issues rather than silently reverting.
  Future<ApiResult<CollectConversion>> convertDeliveryToCollected({
    required String orderId,
  });

  /// [paymentId] rides along for the local-first path only: an order queued
  /// offline needs the picked payment so the sync handler can create the
  /// order's transaction after the order itself lands. The direct online
  /// call ignores it — the POS keeps creating the transaction itself.
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
  });

  Future<ApiResult<TransactionsResponse>> createTransaction({
    required String orderId,
    required String paymentId,
  });

  Future<ApiResult<PaymentsResponse>> getPayments();

  Future<ApiResult<OrderCalculate>> getCalculate({
    required List<Stock> stocks,
    required String type,
    LocationModel? location,
  });
}
