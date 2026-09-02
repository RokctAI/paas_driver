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
