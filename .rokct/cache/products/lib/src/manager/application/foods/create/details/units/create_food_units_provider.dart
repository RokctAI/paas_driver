import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:products_sdk/src/common/domain/interface/seller_catalog.dart';
import 'package:products_sdk/src/manager/application/foods/create/details/units/create_food_units_notifier.dart';
import 'package:products_sdk/src/manager/application/foods/create/details/units/create_food_units_state.dart';

final createFoodUnitsProvider =
    StateNotifierProvider<CreateFoodUnitsNotifier, CreateFoodUnitsState>(
  (ref) =>
      CreateFoodUnitsNotifier(GetIt.instance<SellerCatalogRepositoryFacade>()),
);
