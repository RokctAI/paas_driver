// Ported from paas_manager lib/application/profile/profile_provider.dart
// (users_sdk manager consume, fork plan S-2 / migration bucket b).
// Resolution via base_sdk's injection getters (edit_profile_provider
// precedent): UserRepositoryFacade is registered by
// UsersSdkDependencies.register in the generated main.dart sdk-di block.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:base_sdk/src/di/injection.dart';

import 'profile_notifier.dart';
import 'profile_state.dart';

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>(
  (ref) => ProfileNotifier(userRepository),
);
