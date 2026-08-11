import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/models/data/location.dart';
import 'package:base_sdk/src/models/response/transactions_response.dart';
import 'package:base_sdk/src/services/enums.dart';
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
  Future<ApiResult<OrdersPaginateResponse>> getOrders({
    OrderStatus? status,
    int? page,
    String? from,
    String? to,
  });

  Future<ApiResult<OrdersPaginateResponse>> getHistoryOrders({
    int? page,
    String? from,
    String? to,
  });

  Future<ApiResult<SingleOrderResponse>> getOrderDetails({int? orderId});

  Future<ApiResult<OrderStatusResponse>> updateOrderStatus({
    required OrderStatus status,
    int? orderId,
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
    int? tableId,
    String? floor,
    String? house,
    int? paymentId,
  });

  Future<ApiResult<TransactionsResponse>> createTransaction({
    required int orderId,
    required int paymentId,
  });

  Future<ApiResult<PaymentsResponse>> getPayments();

  Future<ApiResult<OrderCalculate>> getCalculate({
    required List<Stock> stocks,
    required String type,
    LocationModel? location,
  });
}
