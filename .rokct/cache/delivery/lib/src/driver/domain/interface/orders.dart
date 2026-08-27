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

import 'package:delivery_sdk/src/driver/infrastructure/models/data/order_detail.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/order_paginate_response.dart';

import 'package:base_sdk/src/handlers/handlers.dart';

// Order ids are Frappe Order docnames — strings (default hash autoname),
// not ints. Every order-id parameter below is a String.
abstract class CourierOrdersRepositoryFacade {
  Future<ApiResult<OrderDetailModel>> showOrders(String id);

  Future<ApiResult<dynamic>> setCurrentOrder(String? orderId);

  Future<ApiResult<OrderPaginateResponse>> getActiveOrders(int page);

  Future<ApiResult<List<OrderDetailData>>> getAvailableOrders(int page);

  Future<ApiResult<List<OrderDetailData>>> getHistoryOrders(int page,
      {DateTime? start, DateTime? end});

  /// [recipientAgeVerified] is only meaningful when moving an 18+
  /// (contains_adult_items) order to "delivered": it is the courier's
  /// confirmation that he checked the recipient's ID at the door. The
  /// backend refuses to complete a flagged order without it.
  Future<ApiResult<dynamic>> updateOrder(String? orderId, String? status,
      {bool recipientAgeVerified = false});

  Future<ApiResult<dynamic>> confirmCodCollection(
      String? orderId, num amountReceived);

  Future<ApiResult<dynamic>> convertCodToCredit(String? orderId);

  Future<ApiResult<dynamic>> uploadImage(String? orderId, String? image);

  Future<ApiResult<void>> addReview(
    String orderId, {
    required double rating,
    required String comment,
  });

  Future<ApiResult<void>> cancelOrder(String orderId, String note);

  Future<ApiResult<OrderPaginateResponse>> fetchCurrentOrder();

  Future<ApiResult<OrderDetailModel>> setOrder(String orderId);
}
