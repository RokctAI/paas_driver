import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:delivery_sdk/src/driver/di/driver_delivery_di.dart';
import 'package:delivery_sdk/src/driver/application/profile/notifier/profile_edit_notifier.dart';
import 'package:delivery_sdk/src/driver/application/profile/state/profile_edit_state.dart';

final profileEditProvider =
    StateNotifierProvider<ProfileEditNotifier, ProfileEditState>(
  (ref) => ProfileEditNotifier(courierRepository),
);
