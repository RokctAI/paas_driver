import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/manager/application/foods/edit/stocks/addons/edit_food_addons_notifier.dart';
import 'package:products_sdk/src/manager/application/foods/edit/stocks/addons/edit_food_addons_state.dart';

final editFoodAddonsProvider =
    StateNotifierProvider<EditFoodAddonsNotifier, EditFoodAddonsState>(
  (ref) =>
      EditFoodAddonsNotifier(GetIt.instance<SellerProductsRepositoryFacade>()),
);
