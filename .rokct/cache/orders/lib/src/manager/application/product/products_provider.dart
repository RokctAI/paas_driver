import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:orders_sdk/src/manager/domain/interface/pos_products.dart';

import 'products_state.dart';
import 'products_notifier.dart';

final productsProvider = StateNotifierProvider<ProductsNotifier, ProductsState>(
  (ref) => ProductsNotifier(GetIt.instance<PosProductsRepositoryFacade>()),
);
