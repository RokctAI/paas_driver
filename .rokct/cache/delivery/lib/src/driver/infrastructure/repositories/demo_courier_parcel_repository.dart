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

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/models/data/parcel_order.dart';

import 'package:delivery_sdk/src/driver/domain/interface/parcel.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/demo_delivery_seed.dart';

/// Demo-only [CourierParcelRepositoryFacade] (`--dart-define=IS_DEMO=true`):
/// serves [DemoDeliverySeed] parcels offline through the same
/// [ParcelOrder.fromJson] parser the HTTP repository uses. Registered in
/// place of [CourierParcelRepository] by DriverDeliveryDependencies when
/// demo mode is on. Never used in production; write actions mutate the
/// in-memory seed overlay only.
class DemoCourierParcelRepository implements CourierParcelRepositoryFacade {
  static const _activeStatuses = {'accepted', 'on_a_way'};

  List<ParcelOrder> _parse(Iterable<Map<String, dynamic>> maps) =>
      maps.map(ParcelOrder.fromJson).toList();

  @override
  Future<ApiResult<List<ParcelOrder>>> getActiveOrders(int page) async {
    if (page > 1) return const ApiResult.success(data: []);
    return ApiResult.success(
      data: _parse(DemoDeliverySeed.parcels()
          .where((p) => _activeStatuses.contains(p['status']))),
    );
  }

  @override
  Future<ApiResult<List<ParcelOrder>>> getAvailableOrders(int page) async {
    if (page > 1) return const ApiResult.success(data: []);
    return ApiResult.success(
      data: _parse(
          DemoDeliverySeed.parcels().where((p) => p['status'] == 'ready')),
    );
  }

  @override
  Future<ApiResult<List<ParcelOrder>>> getHistoryOrders(int page,
      {DateTime? start, DateTime? end}) async {
    if (page > 1) return const ApiResult.success(data: []);
    // The date filter is ignored on purpose: the demo history is always
    // visible regardless of the picker's range.
    return ApiResult.success(
      data: _parse(
          DemoDeliverySeed.parcels().where((p) => p['status'] == 'delivered')),
    );
  }

  @override
  Future<ApiResult<ParcelOrder>> showParcel(String id) async {
    final parcel = DemoDeliverySeed.parcelById(id);
    if (parcel == null) {
      return const ApiResult.failure(
          error: 'Parcel not found', statusCode: 404);
    }
    return ApiResult.success(data: ParcelOrder.fromJson(parcel));
  }

  @override
  Future<ApiResult<ParcelOrder>> setParcel(String orderId) async {
    final parcel = DemoDeliverySeed.parcelById(orderId);
    if (parcel == null) {
      return const ApiResult.failure(
          error: 'Parcel not found', statusCode: 404);
    }
    DemoDeliverySeed.currentParcelId = orderId;
    return ApiResult.success(data: ParcelOrder.fromJson(parcel));
  }

  @override
  Future<ApiResult<dynamic>> setCurrentOrder(String? orderId) async {
    DemoDeliverySeed.currentParcelId = orderId;
    return const ApiResult.success(data: true);
  }

  @override
  Future<ApiResult<dynamic>> updateParcel(
      String? parcelId, String? status) async {
    if (parcelId != null && status != null) {
      DemoDeliverySeed.parcelStatusOverlay[parcelId] = status;
    }
    return const ApiResult.success(data: true);
  }

  @override
  Future<ApiResult<dynamic>> confirmParcelCodCollection(
      String? parcelId, num amountReceived) async {
    return const ApiResult.success(data: true);
  }

  @override
  Future<ApiResult<void>> addReviewParcel(
    String orderId, {
    required double rating,
    required String comment,
  }) async {
    return const ApiResult.success(data: null);
  }
}
