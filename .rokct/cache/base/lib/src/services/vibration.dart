// Copyright (c) 2026 RokctAI
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

import 'package:flutter/services.dart';

enum FeedbackType {
  success,
  error,
  warning,
  selection,
  impact,
  heavy,
  medium,
  light,
}

class Vibrate {
  static const MethodChannel _channel = MethodChannel('vibrate');
  static const Duration defaultVibrationDuration = Duration(milliseconds: 500);

  static Future vibrate() => _channel.invokeMethod('vibrate', {
        'duration': defaultVibrationDuration.inMilliseconds,
      });

  static Future<bool> get canVibrate async {
    final bool isOn = await _channel.invokeMethod('canVibrate');
    return isOn;
  }

  static void feedback(FeedbackType type) {
    switch (type) {
      case FeedbackType.impact:
        _channel.invokeMethod('impact');
        break;
      case FeedbackType.error:
        _channel.invokeMethod('error');
        break;
      case FeedbackType.success:
        _channel.invokeMethod('success');
        break;
      case FeedbackType.warning:
        _channel.invokeMethod('warning');
        break;
      case FeedbackType.selection:
        _channel.invokeMethod('selection');
        break;
      case FeedbackType.heavy:
        _channel.invokeMethod('heavy');
        break;
      case FeedbackType.medium:
        _channel.invokeMethod('medium');
        break;
      case FeedbackType.light:
        _channel.invokeMethod('light');
        break;
    }
  }

  static Future vibrateWithPauses(Iterable<Duration> pauses) async {
    for (final Duration d in pauses) {
      await vibrate();
      await Future.delayed(defaultVibrationDuration);
      await Future.delayed(d);
    }
    await vibrate();
  }
}
