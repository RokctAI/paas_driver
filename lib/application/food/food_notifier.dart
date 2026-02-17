import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'food_state.dart';

class FoodNotifier extends StateNotifier<FoodState> {
  FoodNotifier() : super(const FoodState());

  void changeToggle(bool toggle) {
    state = state.copyWith(toggle: toggle);
  }

  void changeTimeIndex(int index) {
    state = state.copyWith(timeIndex: index);
  }
}
