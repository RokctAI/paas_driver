import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../infrastructure/models/models.dart';
import '../handlers/handlers.dart';

abstract class UserRepository {
  Future<ApiResult<DeliveryResponse>> getDriverDetails();

  Future<ApiResult<StatisticsResponse>> getDriverStatistics();

  Future<ApiResult<ProfileResponse>> updateGeneralInfo({
    required String firstName,
    String? lastName,
    String? phone,
    String? email,
    String? password,
    String? confirmPassword,
  });

  Future<ApiResult<DeliveryResponse>> editCarInfo({
    required String type,
    required String brand,
    required String model,
    required String number,
    required String color,
    required String height,
    required String weight,
    required String length,
    required String width,
    String? imageUrl,
  });

  Future<ApiResult<DeliveryResponse>> createCarInfo({
    required String type,
    required String brand,
    required String model,
    required String number,
    required String color,
    required String height,
    required String weight,
    required String length,
    required String width,
    String? imageUrl,
  });

  Future<ApiResult<StatisticsIncomeResponse>> getStatistics(
      {required DateTime startTime, required DateTime endTime});

  Future<ApiResult<StatisticsOrderResponse>> getStatisticsOrder(
      {DateTime? startTime, DateTime? endTime, int? page, int? perPage});

  Future<ApiResult<ProfileResponse>> getProfileDetails();

  Future<ApiResult<RequestModelResponse>> getRequestModel();

  Future<ApiResult<dynamic>> setOnline();

  Future<ApiResult<dynamic>> setCurrentLocation(LatLng location);

  Future<ApiResult<ProfileResponse>> editProfile({required EditProfile? user});

  Future<ApiResult<ProfileResponse>> updateProfileImage({
    String? firstName,
    String? imageUrl,
  });

  Future<ApiResult<ProfileResponse>> updatePassword({
    required String password,
    required String passwordConfirmation,
  });

  Future<ApiResult<void>> updateFirebaseToken(String? token);



  Future<ApiResult<dynamic>> deleteAccount();

  Future<ApiResult<void>> updateDeliveryZones({
    required List<LatLng> points,
  });

  Future<ApiResult<DeliveryZonePaginate>> getDeliveryZone();
}
