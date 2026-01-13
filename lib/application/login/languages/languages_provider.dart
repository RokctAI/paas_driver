import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/di/dependency_manager.dart';
import 'languages_notifier.dart';
import 'languages_state.dart';

final languagesProvider =
    StateNotifierProvider<LanguageNotifier, LanguageState>(
  (ref) => LanguageNotifier(settingsRepository),
);
