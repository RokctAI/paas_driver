import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driver/infrastructure/services/app_helpers.dart';

import 'push_order_state.dart';

class PushOrderNotifier extends StateNotifier<PushOrderState> {
  PushOrderNotifier() : super(const PushOrderState());

  Timer? _timer;
  int _initialTime = AppHelpers.getAppDeliveryTime();

  void disposeTimer() {
    _timer?.cancel();
  }

  void startTimer() {
    _timer?.cancel();
    _initialTime = AppHelpers.getAppDeliveryTime();
    if (_timer != null) {
      _initialTime = AppHelpers.getAppDeliveryTime();
      _timer?.cancel();
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_initialTime < 1) {
        _timer?.cancel();
        state = state.copyWith(isTimeOut: true);
      } else {
        _initialTime--;
        state = state.copyWith(
          isTimeOut: false,
          timerText: formatHHMMSS(_initialTime),
        );
      }
    });
  }

  String formatHHMMSS(int seconds) {
    seconds = (seconds % 3600).truncate();
    String secondsStr = (seconds % 60).toString().padLeft(2, '0');
    return "$secondsStr s";
  }

  void changeLoading() {
    state = state.copyWith(isLoading: !state.isLoading);
  }
}
