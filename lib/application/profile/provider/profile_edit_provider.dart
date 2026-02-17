import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:driver/domain/di/dependency_manager.dart';
import '../notifier/profile_edit_notifier.dart';
import '../state/profile_edit_state.dart';

final profileEditProvider =
    StateNotifierProvider<ProfileEditNotifier, ProfileEditState>(
      (ref) => ProfileEditNotifier(userRepository),
    );
