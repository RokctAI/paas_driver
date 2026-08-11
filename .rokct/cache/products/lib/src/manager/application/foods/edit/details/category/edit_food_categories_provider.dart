import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:products_sdk/src/manager/application/foods/edit/details/category/edit_food_categories_notifier.dart';
import 'package:products_sdk/src/manager/application/foods/edit/details/category/edit_food_categories_state.dart';

final editFoodCategoriesProvider =
    StateNotifierProvider<EditFoodCategoriesNotifier, EditFoodCategoriesState>(
  (ref) => EditFoodCategoriesNotifier(),
);
