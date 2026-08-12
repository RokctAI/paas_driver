import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:delivery_sdk/src/driver/application/driver/driver_notifier.dart';
import 'package:delivery_sdk/src/driver/application/driver/driver_state.dart';

final driverProvider = StateNotifierProvider<DriverNotifier, DriverState>(
  (ref) => DriverNotifier(),
);
