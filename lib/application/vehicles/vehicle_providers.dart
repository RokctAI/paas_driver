import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/di/dependency_manager.dart';
import 'vehicle_type_notifier.dart';
import 'vehicle_type_state.dart';

final vehicleTypeProvider =
StateNotifierProvider<VehicleTypeNotifier, VehicleTypeState>((ref) {
  return VehicleTypeNotifier(userRepository); // comes from GetIt
});
