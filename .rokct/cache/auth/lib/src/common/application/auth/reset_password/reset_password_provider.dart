import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:base_sdk/src/di/injection.dart';

import 'package:auth_sdk/src/common/application/auth/reset_password/reset_password_notifier.dart';
import 'package:auth_sdk/src/common/application/auth/reset_password/reset_password_state.dart';

final resetPasswordProvider =
    StateNotifierProvider<ResetPasswordNotifier, ResetPasswordState>(
  (ref) => ResetPasswordNotifier(authRepository, userRepository),
);
