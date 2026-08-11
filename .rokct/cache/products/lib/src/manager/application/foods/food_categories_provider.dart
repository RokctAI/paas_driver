import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:products_sdk/src/common/domain/interface/seller_catalog.dart';
import 'package:products_sdk/src/manager/application/foods/food_categories_notifier.dart';
import 'package:products_sdk/src/manager/application/foods/food_categories_state.dart';

final foodCategoriesProvider =
    StateNotifierProvider<FoodCategoriesNotifier, FoodCategoriesState>(
  (ref) => FoodCategoriesNotifier(
    GetIt.instance<SellerCatalogRepositoryFacade>(),
  ),
);
