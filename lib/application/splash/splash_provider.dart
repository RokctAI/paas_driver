import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:driver/domain/di/dependency_manager.dart';
import 'splash_notifier.dart';
import 'package:base_sdk/src/application/splash/splash_state.dart';

final splashProvider = StateNotifierProvider<SplashNotifier, SplashState>(
  (ref) => SplashNotifier(settingsRepository, userRepository),
);
