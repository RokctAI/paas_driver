import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'reset_password_state.dart';
import 'reset_password_notifier.dart';
import 'package:driver/domain/di/dependency_manager.dart';

final resetPasswordProvider =
    StateNotifierProvider<ResetPasswordNotifier, ResetPasswordState>(
      (ref) => ResetPasswordNotifier(authRepository, userRepository),
    );
