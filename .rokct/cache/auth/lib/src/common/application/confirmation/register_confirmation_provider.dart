import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:base_sdk/src/di/injection.dart';
import 'package:auth_sdk/src/common/application/confirmation/register_confirmation_notifier.dart';
import 'package:auth_sdk/src/common/application/confirmation/register_confirmation_state.dart';

final registerConfirmationProvider = StateNotifierProvider.autoDispose<
        RegisterConfirmationNotifier, RegisterConfirmationState>(
    (ref) => RegisterConfirmationNotifier(authRepository, userRepository));
