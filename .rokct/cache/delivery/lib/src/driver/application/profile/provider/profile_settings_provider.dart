import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:delivery_sdk/src/driver/di/driver_delivery_di.dart';
import 'package:delivery_sdk/src/driver/application/profile/notifier/profile_settings_notifier.dart';
import 'package:delivery_sdk/src/driver/application/profile/state/profile_settings_state.dart';

final profileSettingsProvider =
    StateNotifierProvider<ProfileSettingsNotifier, ProfileSettingsState>(
  (ref) => ProfileSettingsNotifier(userRepository, courierRepository),
);
