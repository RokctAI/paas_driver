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

import 'package:delivery_sdk/src/driver/domain/interface/orders.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/order_detail.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/order_paginate_response.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/driver_day_report.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/demo_delivery_seed.dart';

/// Demo-only [CourierOrdersRepositoryFacade] (`--dart-define=IS_DEMO=true`):
/// serves [DemoDeliverySeed] orders through the exact model parsers the HTTP
/// repository uses, entirely offline. Registered in place of
/// [CourierOrdersRepository] by DriverDeliveryDependencies when demo mode is
/// on (MockAuthRepository / DemoLmsRepository precedent). Never used in
/// production; write actions mutate the in-memory seed overlay only.
class DemoCourierOrdersRepository implements CourierOrdersRepositoryFacade {
  static const _activeStatuses = {'accepted', 'ready', 'on_a_way'};

  /// Available orders are seeded with an explicit `deliveryman: null` and
  /// status `ready` — the same shape the real "empty-deliveryman" endpoint
  /// filter returns. Accepting one (updateOrder -> overlay) moves it to the
  /// active list, like the backend would.
  bool _isAvailable(Map<String, dynamic> o) =>
      o.containsKey('deliveryman') &&
      o['deliveryman'] == null &&
      o['status'] == 'ready';

  List<OrderDetailData> _parse(Iterable<Map<String, dynamic>> maps) =>
      maps.map(OrderDetailData.fromJson).toList();

  @override
  Future<ApiResult<OrderPaginateResponse>> getActiveOrders(int page) async {
    if (page > 1) {
      // Single demo page: an empty follow-up page ends pull-to-load cleanly.
      return ApiResult.success(
          data: OrderPaginateResponse(data: const [], meta: null));
    }
    final active = DemoDeliverySeed.orders()
        .where((o) => _activeStatuses.contains(o['status']) && !_isAvailable(o))
        .toList();
    return ApiResult.success(
      data: OrderPaginateResponse.fromJson({
        'data': active,
        'meta': {'total': active.length},
      }),
    );
  }

  @override
  Future<ApiResult<List<OrderDetailData>>> getAvailableOrders(int page) async {
    if (page > 1) return const ApiResult.success(data: []);
    return ApiResult.success(
      data: _parse(DemoDeliverySeed.orders().where(_isAvailable)),
    );
  }

  /// Demo day report, summed from the seed exactly as the server sums
  /// the real rows: Delivered work only, delivery fees for the earnings,
  /// COD amounts for the cash he is carrying. The date bounds are
  /// ignored on purpose — the demo seed is always "today".
  @override
  Future<ApiResult<DriverDayReport>> getDayReport({
    required DateTime from,
    required DateTime to,
  }) async {
    final delivered = DemoDeliverySeed.orders()
        .where((o) => o['status'] == 'delivered')
        .toList();
    num earned = 0;
    num cash = 0;
    var cashCount = 0;
    num lastFee = 0;
    for (final order in delivered) {
      final fee = _asNum(order['delivery_fee']);
      earned += fee;
      lastFee = fee;
      final collected = _asNum(order['cod_collected_amount']);
      if (collected > 0) {
        cash += collected;
        cashCount++;
      }
    }
    return ApiResult.success(
      data: DriverDayReport(
        earned: earned,
        deliveredCount: delivered.length,
        totalCount: DemoDeliverySeed.orders().length,
        lastFee: lastFee,
        cashOnHand: cash,
        cashOrderCount: cashCount,
      ),
    );
  }

  /// Demo driver is always comfortably inside his allowance — the gate
  /// is a real state and demo mode is not the place to fake a driver
  /// into it.
  @override
  Future<ApiResult<DriverWorkStatus>> getWorkStatus() async =>
      const ApiResult.success(
        data: DriverWorkStatus(
          allowance: 2000,
          balance: 0,
          owing: 0,
          canTakeWork: true,
        ),
      );

  static num _asNum(dynamic value) =>
      value is num ? value : num.tryParse('$value') ?? 0;

  @override
  Future<ApiResult<List<OrderDetailData>>> getHistoryOrders(int page,
      {DateTime? start, DateTime? end}) async {
    if (page > 1) return const ApiResult.success(data: []);
    // The date filter is ignored on purpose: the demo history is always
    // visible regardless of the picker's range.
    return ApiResult.success(
      data: _parse(
          DemoDeliverySeed.orders().where((o) => o['status'] == 'delivered')),
    );
  }

  @override
  Future<ApiResult<OrderDetailModel>> showOrders(String id) async {
    final order = DemoDeliverySeed.orderById(id);
    if (order == null) {
      return const ApiResult.failure(error: 'Order not found', statusCode: 404);
    }
    return ApiResult.success(data: OrderDetailModel.fromJson({'data': order}));
  }

  @override
  Future<ApiResult<OrderPaginateResponse>> fetchCurrentOrder() async {
    final id = DemoDeliverySeed.currentOrderId;
    final order = id == null ? null : DemoDeliverySeed.orderById(id);
    final done =
        order == null || {'delivered', 'canceled'}.contains(order['status']);
    return ApiResult.success(
      data: OrderPaginateResponse.fromJson({
        'data': done ? [] : [order],
        'meta': {'total': done ? 0 : 1},
      }),
    );
  }

  @override
  Future<ApiResult<OrderDetailModel>> setOrder(String orderId) async {
    final order = DemoDeliverySeed.orderById(orderId);
    if (order == null) {
      return const ApiResult.failure(error: 'Order not found', statusCode: 404);
    }
    DemoDeliverySeed.currentOrderId = orderId;
    return ApiResult.success(data: OrderDetailModel.fromJson({'data': order}));
  }

  @override
  Future<ApiResult<dynamic>> setCurrentOrder(String? orderId) async {
    DemoDeliverySeed.currentOrderId = orderId;
    return const ApiResult.success(data: true);
  }

  @override
  Future<ApiResult<dynamic>> updateOrder(String? orderId, String? status,
      {bool recipientAgeVerified = false}) async {
    // recipientAgeVerified is accepted to satisfy the facade's 18+ ID
    // verification contract; demo mode has no backend gate, so the flag is
    // simply ignored and the overlay updates as before.
    if (orderId != null && status != null) {
      DemoDeliverySeed.orderStatusOverlay[orderId] = status;
    }
    return const ApiResult.success(data: true);
  }

  @override
  Future<ApiResult<dynamic>> confirmCodCollection(
      String? orderId, num amountReceived) async {
    return const ApiResult.success(data: true);
  }

  @override
  Future<ApiResult<dynamic>> convertCodToCredit(String? orderId) async {
    return const ApiResult.success(data: true);
  }

  @override
  Future<ApiResult<dynamic>> uploadImage(
      String? orderId, String? image) async {
    return const ApiResult.success(data: true);
  }

  @override
  Future<ApiResult<void>> addReview(
    String orderId, {
    required double rating,
    required String comment,
  }) async {
    return const ApiResult.success(data: null);
  }

  @override
  Future<ApiResult<void>> cancelOrder(String orderId, String note) async {
    DemoDeliverySeed.orderStatusOverlay[orderId] = 'canceled';
    if (DemoDeliverySeed.currentOrderId == orderId) {
      DemoDeliverySeed.currentOrderId = null;
    }
    return const ApiResult.success(data: null);
  }
}
