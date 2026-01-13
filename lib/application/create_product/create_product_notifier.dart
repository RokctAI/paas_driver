import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'create_product_state.dart';

class CreateProductNotifier extends StateNotifier<CreateProductState> {
  CreateProductNotifier() : super(const CreateProductState());

  void changeIndex(int index) {
    state = state.copyWith(currentIndex: index);
  }
}
