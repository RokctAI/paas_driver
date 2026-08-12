import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:delivery_sdk/src/driver/di/driver_delivery_di.dart';
import 'package:delivery_sdk/src/driver/application/profile/notifier/profile_image_notifier.dart';
import 'package:delivery_sdk/src/driver/application/profile/state/profile_image_state.dart';

final profileImageProvider =
    StateNotifierProvider<ProfileImageNotifier, ProfileImageState>(
  (ref) => ProfileImageNotifier(userRepository, galleryRepository),
);
