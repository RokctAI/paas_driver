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

import 'package:flutter/material.dart';
import 'package:base_sdk/src/constants/demo_images.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/domain/interface/orders.dart';
import 'package:base_sdk/src/models/data/coupon_data.dart';
import 'package:base_sdk/src/models/data/get_calculate_data.dart';
import 'package:base_sdk/src/models/data/local_location.dart';
import 'package:base_sdk/src/models/data/order_active_model.dart';
import 'package:base_sdk/src/models/data/order_body_data.dart';
import 'package:base_sdk/src/models/data/refund_data.dart';
import 'package:base_sdk/src/models/data/shop_data.dart';
import 'package:base_sdk/src/models/data/translation.dart';
import 'package:base_sdk/src/models/data/cashback_model.dart';
import 'package:base_sdk/src/models/response/coupon_response.dart';
import 'package:base_sdk/src/models/response/order_paginate_response.dart';
import 'package:base_sdk/src/services/enums.dart';

class MockOrdersRepository implements OrdersRepositoryFacade {
  final OrderActiveModel _demoOrder = OrderActiveModel(
    id: "1",
    status: "delivered",
    totalPrice: 45.0,
    createdAt: DateTime.now(),
    shop: ShopData(
      id: "demo_shop_1",
      translation: Translation(title: "Nonna's Pizzeria"),
      logoImg: DemoImages.category,
    ),
    details: [],
    currencyModel: CurrencyModel(
      id: "1",
      symbol: "\$",
      title: "USD",
      active: true,
    ),
  );

  @override
  Future<ApiResult<void>> addReview(
    String orderId, {
    required double rating,
    required String comment,
  }) async {
    return ApiResult.success(data: null);
  }

  @override
  Future<ApiResult<void>> cancelOrder(String orderId) async {
    return ApiResult.success(data: null);
  }

  @override
  Future<ApiResult<CashbackModel>> checkCashback({
    required String shopId,
    required double amount,
  }) async {
    return ApiResult.success(data: CashbackModel(price: 0));
  }

  @override
  Future<ApiResult<CouponResponse>> checkCoupon({
    required String coupon,
    required String shopId,
  }) async {
    return ApiResult.success(
      data: CouponResponse(data: CouponData(price: 5.0, type: "fixed")),
    );
  }

  @override
  Future<ApiResult> createAutoOrder({
    required String from,
    required String orderId,
    String? to,
    String? cronPattern,
    String? paymentMethod,
    String? savedCardId,
  }) async {
    return ApiResult.success(data: null);
  }

  @override
  Future<ApiResult<OrderActiveModel>> createOrder(
    OrderBodyData orderBody,
  ) async {
    return ApiResult.success(
      data: _demoOrder.copyWith(id: "2", status: "pending"),
    );
  }

  @override
  Future<ApiResult<void>> createRepeatingOrder({
    required String orderId,
    required String startDate,
    required String cronPattern,
    String? endDate,
  }) async {
    return ApiResult.success(data: null);
  }

  @override
  Future<ApiResult> deleteAutoOrder(String orderId) async {
    return ApiResult.success(data: null);
  }

  @override
  Future<ApiResult<void>> deleteRepeatingOrder({
    required String repeatingOrderId,
  }) async {
    return ApiResult.success(data: null);
  }

  @override
  Future<ApiResult<OrderPaginateResponse>> getActiveOrders(int page) async {
    return ApiResult.success(
      data: OrderPaginateResponse(
        data: [_demoOrder.copyWith(id: "3", status: "accepted")],
      ),
    );
  }

  @override
  Future<ApiResult<GetCalculateModel>> getCalculate({
    required String cartId,
    required double lat,
    required double long,
    required DeliveryTypeEnum type,
    String? coupon,
  }) async {
    return ApiResult.success(
      data: GetCalculateModel(
        totalPrice: 50.0,
        totalTax: 5.0,
        totalShopTax: 2.5,
        price: 45.0,
        deliveryFee: 2.5,
        serviceFee: 0.0,
      ),
    );
  }

  @override
  Future<ApiResult<OrderPaginateResponse>> getCompletedOrders(int page) async {
    return ApiResult.success(data: OrderPaginateResponse(data: [_demoOrder]));
  }

  @override
  Future<ApiResult<LocalLocation>> getDriverLocation(String deliveryId) async {
    return ApiResult.success(
      data: LocalLocation(latitude: 37.7749, longitude: -122.4194),
    );
  }

  @override
  Future<ApiResult<OrderPaginateResponse>> getHistoryOrders(int page) async {
    return ApiResult.success(
      data: OrderPaginateResponse(
        data: [
          _demoOrder,
          _demoOrder.copyWith(
            id: "4",
            createdAt: DateTime.now().subtract(Duration(days: 1)),
          ),
        ],
      ),
    );
  }

  @override
  Future<ApiResult<RefundOrdersModel>> getRefundOrders(int page) async {
    return ApiResult.success(data: RefundOrdersModel(data: []));
  }

  @override
  Future<ApiResult<OrderActiveModel>> getSingleOrder(String orderId) async {
    return ApiResult.success(data: _demoOrder);
  }

  @override
  Future<ApiResult> pauseAutoOrder(String autoOrderId) async {
    return ApiResult.success(data: null);
  }

  @override
  Future<ApiResult<String>> process(
    OrderBodyData orderBody,
    String name, {
    BuildContext? context,
    bool forceCardPayment = false,
    bool enableTokenization = false,
  }) async {
    return ApiResult.success(data: "http://mock-payment-url.com");
  }

  @override
  Future<ApiResult<void>> refundOrder(String orderId, String title) async {
    return ApiResult.success(data: null);
  }

  @override
  Future<ApiResult> resumeAutoOrder(String autoOrderId) async {
    return ApiResult.success(data: null);
  }

  @override
  Future<ApiResult<String>> tipProcess({
    required String orderId,
    required double tip,
  }) async {
    return ApiResult.success(data: "http://mock-tip-payment-url.com");
  }
}
