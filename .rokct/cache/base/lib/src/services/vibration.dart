// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.


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
