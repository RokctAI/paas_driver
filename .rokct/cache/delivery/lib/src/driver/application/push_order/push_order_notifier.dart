import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

import 'package:delivery_sdk/src/driver/application/push_order/push_order_state.dart';
import 'package:delivery_sdk/src/driver/infrastructure/services/courier_helpers.dart';

class PushOrderNotifier extends StateNotifier<PushOrderState> {
  PushOrderNotifier() : super(const PushOrderState());

  Timer? _timer;
  int _initialTime = CourierHelpers.getAppDeliveryTime();

  void disposeTimer() {
    _timer?.cancel();
  }

  void startTimer() {
    _timer?.cancel();
    _initialTime = CourierHelpers.getAppDeliveryTime();
    if (_timer != null) {
      _initialTime = CourierHelpers.getAppDeliveryTime();
      _timer?.cancel();
    }
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (_initialTime < 1) {
          _timer?.cancel();
          state = state.copyWith(
            isTimeOut: true,
          );
        } else {
          _initialTime--;
          state = state.copyWith(
            isTimeOut: false,
            timerText: formatHHMMSS(_initialTime),
          );
        }
      },
    );
  }

  String formatHHMMSS(int seconds) {
    seconds = (seconds % 3600).truncate();
    String secondsStr = (seconds % 60).toString().padLeft(2, '0');
    return "$secondsStr s";
  }

  changeLoading() {
    state = state.copyWith(isLoading: !state.isLoading);
  }
}
