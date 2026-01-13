import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'food_notifier.dart';
import 'food_state.dart';

final foodProvider = StateNotifierProvider<FoodNotifier, FoodState>(
  (ref) => FoodNotifier(),
);
