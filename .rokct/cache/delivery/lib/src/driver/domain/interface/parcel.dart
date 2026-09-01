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

// Parcel order ids are Frappe Parcel Order docnames — strings (default
// hash autoname), not ints; base_sdk's ParcelOrder.id is already a
// String. Every parcel/order-id parameter below is a String.
abstract class CourierParcelRepositoryFacade {
  Future<ApiResult<ParcelOrder>> showParcel(String id);

  Future<ApiResult<dynamic>> setCurrentOrder(String? orderId);

  Future<ApiResult<List<ParcelOrder>>> getActiveOrders(int page);

  Future<ApiResult<List<ParcelOrder>>> getAvailableOrders(int page);

  Future<ApiResult<List<ParcelOrder>>> getHistoryOrders(int page,
      {DateTime? start, DateTime? end});

  Future<ApiResult<dynamic>> updateParcel(String? parcelId, String? status);

  Future<ApiResult<dynamic>> confirmParcelCodCollection(
      String? parcelId, num amountReceived);

  Future<ApiResult<void>> addReviewParcel(
    String orderId, {
    required double rating,
    required String comment,
  });

  Future<ApiResult<ParcelOrder>> setParcel(String orderId);
}
