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


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:base_sdk/src/domain/interface/delivery_points.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/application/delivery_points/delivery_points_state.dart';
import 'package:base_sdk/src/handlers/api_result.dart';

class DeliveryPointsNotifier extends StateNotifier<DeliveryPointsState> {
  final DeliveryPointsRepositoryFacade _deliveryPointsRepository;

  DeliveryPointsNotifier(this._deliveryPointsRepository)
      : super(const DeliveryPointsState());

  Future<void> fetchDeliveryPoints(
    BuildContext context, {
    required double latitude,
    required double longitude,
  }) async {
    state = state.copyWith(isLoading: true);
    final response = await _deliveryPointsRepository.getDeliveryPoints(
      latitude: latitude,
      longitude: longitude,
    );
    response.when(
      success: (data) {
        state = state.copyWith(isLoading: false, deliveryPoints: data);
      },
      failure: (failure, status) {
        state = state.copyWith(isLoading: false);
        AppHelpers.showCheckTopSnackBar(context, failure.toString());
      },
    );
  }
}
