import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:delivery_sdk/src/driver/domain/interface/courier.dart';
import 'package:delivery_sdk/src/driver/application/vehicles/vehicle_type_state.dart';

class VehicleTypeNotifier extends StateNotifier<VehicleTypeState> {
  final CourierRepositoryFacade repository;

  VehicleTypeNotifier(this.repository)
      : super(const VehicleTypeState.loading()) {
    fetchTypes();
  }

  Future<void> fetchTypes() async {
    final result = await repository.getDeliveryVehicleTypes();
    result.when(
      success: (data) => state = VehicleTypeState.data(data),
      failure: (err, _) => state = VehicleTypeState.error(err),
    );
  }
}
