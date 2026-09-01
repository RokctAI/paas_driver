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
