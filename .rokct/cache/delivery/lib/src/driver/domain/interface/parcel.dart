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
