import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:delivery_sdk/src/driver/application/home/home_notifier.dart';
import 'package:delivery_sdk/src/driver/application/home/home_state.dart';

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>(
  (ref) => HomeNotifier(),
);
