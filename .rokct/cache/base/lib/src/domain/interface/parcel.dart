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


import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/models/response/parcel_paginate_response.dart';

import 'package:base_sdk/src/models/models.dart';

abstract class ParcelRepositoryFacade {
  Future<ApiResult<ParcelTypeResponse>> getTypes();

  Future<ApiResult<ParcelCalculateResponse>> getCalculate({
    required String typeId,
    required LocationModel from,
    required LocationModel to,
  });

  Future<ApiResult> orderParcel({
    required String typeId,
    required LocationModel from,
    required String fromTitle,
    required LocationModel to,
    required String toTitle,
    required String time,
    required String note,
    required String phoneFrom,
    required String phoneTo,
    required String usernameTo,
    required String usernameFrom,
    required String floorTo,
    required String floorFrom,
    required String houseFrom,
    required String houseTo,
    required String comment,
    required String value,
    required String instruction,
    required bool notify,
  });

  Future<ApiResult<ParcelPaginateResponse>> getActiveParcel(int page);

  Future<ApiResult<ParcelPaginateResponse>> getHistoryParcel(int page);

  Future<ApiResult<ParcelOrder>> getSingleParcel(String orderId);

  Future<ApiResult<void>> addReview(
    String orderId, {
    required double rating,
    required String comment,
  });

  Future<ApiResult<String>> process(String orderId, String name);

  Future<ApiResult<TransactionsResponse>> createTransaction({
    required String orderId,
    required String paymentId,
  });
}
