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
