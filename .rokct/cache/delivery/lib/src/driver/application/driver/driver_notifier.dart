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
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:base_sdk/src/models/response/driver_show_response.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

import 'package:delivery_sdk/src/driver/application/driver/driver_state.dart';
import 'package:delivery_sdk/src/driver/di/driver_delivery_di.dart';
import 'package:delivery_sdk/src/driver/infrastructure/services/courier_storage.dart';

class DriverNotifier extends StateNotifier<DriverState> {
  DriverNotifier() : super(const DriverState());

  void setDriverData(DeliveryResponse? data) {
    state = state.copyWith(driverData: data);
  }

  /// Fetches the deliveryman settings record and caches it locally.
  ///
  /// Moved from paas_driver's host `splash_notifier.fetchDriverDetails` -
  /// base_sdk's splash knows nothing about couriers, so the home page's init
  /// triggers this instead (driver-lib-regenerable-plan.md section 2,
  /// "splash wiring").
  Future<void> fetchDriverDetails({required BuildContext context}) async {
    final response = await courierRepository.getDriverDetails();
    response.when(
      success: (data) {
        setDriverData(data);
        CourierStorage.setDeliveryInfo(data);
        CourierStorage.setOnline(data.data?.online ?? false);
      },
      failure: (failure, status) {
        AppHelpers.showCheckTopSnackBar(
          context,
          AppHelpers.getTranslation(failure),
        );
        debugPrint('==> error with fetching driver details $failure');
      },
    );
  }
}
