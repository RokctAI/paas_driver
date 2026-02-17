import 'package:freezed_annotation/freezed_annotation.dart';

import '../../infrastructure/models/models.dart';

part 'driver_state.freezed.dart';

@freezed
class DriverState with _$DriverState {
  const factory DriverState({
    DeliveryResponse? driverData,
  }) = _DriverState;

  const DriverState._();
}
