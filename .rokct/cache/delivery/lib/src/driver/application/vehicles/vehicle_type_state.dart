import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:delivery_sdk/src/driver/infrastructure/models/data/delivery_vehicle_type.dart';

part 'vehicle_type_state.freezed.dart';

@freezed
class VehicleTypeState with _$VehicleTypeState {
  const factory VehicleTypeState.loading() = _Loading;
  const factory VehicleTypeState.data(List<DeliveryVehicleType> types) = _Data;
  const factory VehicleTypeState.error(String message) = _Error;
}
