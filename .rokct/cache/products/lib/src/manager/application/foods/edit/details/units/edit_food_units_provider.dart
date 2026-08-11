import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:products_sdk/src/common/domain/interface/seller_catalog.dart';
import 'package:products_sdk/src/manager/application/foods/edit/details/units/edit_food_units_notifier.dart';
import 'package:products_sdk/src/manager/application/foods/edit/details/units/edit_food_units_state.dart';

final editFoodUnitsProvider =
    StateNotifierProvider<EditFoodUnitsNotifier, EditFoodUnitsState>(
  (ref) =>
      EditFoodUnitsNotifier(GetIt.instance<SellerCatalogRepositoryFacade>()),
);
