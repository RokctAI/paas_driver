import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'products_notifier.dart';
import 'products_state.dart';

final productsProvider = StateNotifierProvider<ProductsNotifier, ProductsState>(
  (ref) => ProductsNotifier(),
);
