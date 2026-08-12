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
