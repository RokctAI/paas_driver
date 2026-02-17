import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:driver/domain/di/dependency_manager.dart';
import 'package:driver/domain/handlers/handlers.dart';
import 'package:driver/domain/interface/interfaces.dart';
import '../models/models.dart';
import '../services/services.dart';

class DrawRepositoryImpl implements DrawRepository {
  @override
  Future<ApiResult<DrawRouting>> getRouting({
    required LatLng start,
    required LatLng end,
  }) async {
    try {
      final client = dioHttp.client(requireAuth: false, routing: true);
      final response = await client.get(
        '/v2/directions/driving-car?api_key=${AppConstants.routingKey}&start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}',
      );
      return ApiResult.success(data: DrawRouting.fromJson(response.data));
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}
