import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'product_categories_state.dart';
import 'product_categories_notifier.dart';
import 'package:get_it/get_it.dart';
import 'package:orders_sdk/src/manager/domain/interface/pos_products.dart';

final productCategoriesProvider =
    StateNotifierProvider<ProductCategoriesNotifier, ProductCategoriesState>(
  (ref) => ProductCategoriesNotifier(GetIt.instance<PosProductsRepositoryFacade>()),
);
