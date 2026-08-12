import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_sdk/src/driver/di/driver_delivery_di.dart';
import 'package:delivery_sdk/src/driver/application/vehicles/vehicle_type_notifier.dart';
import 'package:delivery_sdk/src/driver/application/vehicles/vehicle_type_state.dart';

final vehicleTypeProvider =
    StateNotifierProvider<VehicleTypeNotifier, VehicleTypeState>((ref) {
  return VehicleTypeNotifier(courierRepository); // comes from GetIt
});
