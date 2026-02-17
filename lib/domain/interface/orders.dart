import 'package:driver/infrastructure/models/data/order_detail.dart';
import 'package:driver/infrastructure/models/data/order_paginate_response.dart';

import 'package:driver/domain/handlers/handlers.dart';

abstract class OrdersRepositoryFacade {
  Future<ApiResult<OrderDetailModel>> showOrders(int id);

  Future<ApiResult<dynamic>> setCurrentOrder(int? orderId);

  Future<ApiResult<OrderPaginateResponse>> getActiveOrders(int page);

  Future<ApiResult<OrderPaginateResponse>> getProgressOrders(int page);

  Future<ApiResult<List<OrderDetailData>>> getAvailableOrders(int page);

  Future<ApiResult<List<OrderDetailData>>> getHistoryOrders(
    int page, {
    DateTime? start,
    DateTime? end,
    List<String>? status,
  });

  Future<ApiResult<dynamic>> updateOrder(int? orderId, String? status);

  Future<ApiResult<dynamic>> uploadImage(int? orderId, String? image);

  Future<ApiResult<void>> addReview(
    num orderId, {
    required double rating,
    required String comment,
  });

  Future<ApiResult<void>> cancelOrder(int orderId, String note);

  Future<ApiResult<OrderPaginateResponse>> fetchCurrentOrder();

  Future<ApiResult<OrderDetailModel>> setOrder(String orderId);
}
