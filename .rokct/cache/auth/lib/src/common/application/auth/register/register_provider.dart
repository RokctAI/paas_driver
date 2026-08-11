import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:base_sdk/src/di/injection.dart';
import 'package:auth_sdk/src/common/application/auth/register/register_notifier.dart';
import 'package:auth_sdk/src/common/application/auth/register/register_state.dart';

final registerProvider = StateNotifierProvider<RegisterNotifier, RegisterState>(
  (ref) => RegisterNotifier(authRepository, userRepository),
);
