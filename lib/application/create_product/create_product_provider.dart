import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'create_product_notifier.dart';
import 'create_product_state.dart';

final createProductProvider =
    StateNotifierProvider<CreateProductNotifier, CreateProductState>(
  (ref) => CreateProductNotifier(),
);
