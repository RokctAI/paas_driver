import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'driver_notifier.dart';
import 'driver_state.dart';

final driverProvider = StateNotifierProvider<DriverNotifier, DriverState>(
  (ref) => DriverNotifier(),
);
