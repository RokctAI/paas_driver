import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:base_sdk/src/models/response/driver_show_response.dart';


part 'driver_state.freezed.dart';

@freezed
class DriverState with _$DriverState {
  const factory DriverState({
    DeliveryResponse? driverData,
  }) = _DriverState;

  const DriverState._();
}
