import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'delivery_time_state.dart';

class DeliveryTimeNotifier extends StateNotifier<DeliveryTimeState> {
  DeliveryTimeNotifier()
      : super(
          DeliveryTimeState(
            deliveryDate: DateTime.now().toString().substring(0, 10),
          ),
        );

  void setDeliveryDate(String date) {
    state = state.copyWith(deliveryDate: date);
  }
}
