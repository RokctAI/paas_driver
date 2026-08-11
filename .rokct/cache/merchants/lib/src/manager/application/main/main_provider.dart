import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:merchants_sdk/src/manager/application/main/main_notifier.dart';
import 'package:merchants_sdk/src/manager/application/main/main_state.dart';

final mainProvider = StateNotifierProvider<MainNotifier, MainState>(
  (ref) => MainNotifier(),
);
