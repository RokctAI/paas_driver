import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'delivery_type_state.dart';

class DeliveryTypeNotifier extends StateNotifier<DeliveryTypeState> {
  DeliveryTypeNotifier() : super(const DeliveryTypeState());

  void setType(String type) {
    if (type == state.type) {
      return;
    }
    state = state.copyWith(type: type);
  }
}
