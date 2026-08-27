// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
