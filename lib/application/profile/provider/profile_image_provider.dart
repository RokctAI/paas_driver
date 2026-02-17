import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:driver/domain/di/dependency_manager.dart';
import '../notifier/profile_image_notifier.dart';
import '../state/profile_image_state.dart';

final profileImageProvider =
    StateNotifierProvider<ProfileImageNotifier, ProfileImageState>(
      (ref) => ProfileImageNotifier(userRepository, settingsRepository),
    );
