import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:base_sdk/src/di/injection.dart';

import 'package:products_sdk/src/common/application/product/product_notifier.dart';
import 'package:products_sdk/src/common/application/product/product_state.dart';

final productProvider =
    StateNotifierProvider.autoDispose<ProductNotifier, ProductState>(
  (ref) => ProductNotifier(cartRepository, productsRepository),
);
