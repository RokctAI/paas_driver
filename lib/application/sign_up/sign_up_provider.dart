import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sign_up_state.dart';
import 'sign_up_notifier.dart';
import '../../domain/di/dependency_manager.dart';

final signUpProvider =
    StateNotifierProvider.autoDispose<SignUpNotifier, SignUpState>(
  (ref) => SignUpNotifier(authRepository, userRepository),
);
