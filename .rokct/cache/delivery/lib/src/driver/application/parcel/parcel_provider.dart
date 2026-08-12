import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:delivery_sdk/src/driver/di/driver_delivery_di.dart';
import 'package:delivery_sdk/src/driver/application/parcel/parcel_notifier.dart';
import 'package:delivery_sdk/src/driver/application/parcel/parcel_state.dart';

final parcelProvider = StateNotifierProvider<ParcelNotifier, ParcelState>(
  (ref) => ParcelNotifier(parcelRepository),
);
