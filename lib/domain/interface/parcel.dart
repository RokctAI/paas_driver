import 'package:driver/domain/handlers/api_result.dart';
import 'package:driver/infrastructure/models/data/parcel_order.dart';

abstract class ParcelRepositoryFacade {
  Future<ApiResult<ParcelOrder>> showParcel(int id);

  Future<ApiResult<dynamic>> setCurrentOrder(int? orderId);

  Future<ApiResult<List<ParcelOrder>>> getActiveOrders(int page);

  Future<ApiResult<List<ParcelOrder>>> getAvailableOrders(int page);

  Future<ApiResult<List<ParcelOrder>>> getHistoryOrders(
    int page, {
    DateTime? start,
    DateTime? end,
  });

  Future<ApiResult<dynamic>> updateParcel(int? parcelId, String? status);

  Future<ApiResult<void>> addReviewParcel(
    num orderId, {
    required double rating,
    required String comment,
  });

  Future<ApiResult<ParcelOrder>> setParcel(String orderId);
}
