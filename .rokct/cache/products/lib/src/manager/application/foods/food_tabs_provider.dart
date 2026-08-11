import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:products_sdk/src/manager/application/foods/food_tabs_notifier.dart';
import 'package:products_sdk/src/manager/application/foods/food_tabs_state.dart';

final foodTabsProvider =
    StateNotifierProvider<FoodTabsNotifier, FoodTabsState>(
  (ref) => FoodTabsNotifier(),
);
