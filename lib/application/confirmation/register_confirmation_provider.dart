import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'register_confirmation_state.dart';
import 'register_confirmation_notifier.dart';
import '../../domain/di/dependency_manager.dart';

final registerConfirmationProvider = StateNotifierProvider.autoDispose<
    RegisterConfirmationNotifier, RegisterConfirmationState>(
  (ref) => RegisterConfirmationNotifier(authRepository, userRepository),
);
