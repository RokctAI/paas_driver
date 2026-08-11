import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/manager/application/foods/create/stocks/create_food_stocks_notifier.dart';
import 'package:products_sdk/src/manager/application/foods/create/stocks/create_food_stocks_state.dart';

final createFoodStocksProvider =
    StateNotifierProvider<CreateFoodStocksNotifier, CreateFoodStocksState>(
  (ref) =>
      CreateFoodStocksNotifier(GetIt.instance<SellerProductsRepositoryFacade>()),
);
