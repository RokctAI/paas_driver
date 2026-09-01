// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:delivery_sdk/src/driver/infrastructure/models/data/delivery_vehicle_type.dart';

part 'vehicle_type_state.freezed.dart';

@freezed
sealed class VehicleTypeState with _$VehicleTypeState {
  const factory VehicleTypeState.loading() = _Loading;
  const factory VehicleTypeState.data(List<DeliveryVehicleType> types) = _Data;
  const factory VehicleTypeState.error(String message) = _Error;
}
