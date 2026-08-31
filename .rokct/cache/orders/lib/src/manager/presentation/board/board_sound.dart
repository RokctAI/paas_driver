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

import 'package:flutter/services.dart';

/// The POS's sound alert (`orders_table.dart _checkAndPlaySound`): chime
/// when the NEW or ACCEPTED queue grew since the last observation. The POS
/// played a bundled notification.wav through the audioplayers package;
/// this fleet carries no audio dependency, so the chime goes through the
/// engine's own [SystemSound] — no package, no asset, works everywhere the
/// platform exposes an alert sound. The bell's orange activity dot rides
/// the same trigger.
class NewOrderChime {
  int? _previousNewCount;
  int? _previousAcceptedCount;

  /// Feed the current queue sizes; true when a NEW arrival should chime.
  /// The first observation only baselines (no chime on initial load —
  /// same as the POS initializing its previous counts before comparing).
  bool register({required int newCount, required int acceptedCount}) {
    final prevNew = _previousNewCount;
    final prevAccepted = _previousAcceptedCount;
    _previousNewCount = newCount;
    _previousAcceptedCount = acceptedCount;
    if (prevNew == null || prevAccepted == null) return false;
    return newCount > prevNew || acceptedCount > prevAccepted;
  }

  /// Play the alert. Kept separate from [register] so callers can honour
  /// the bell's on/off state, and so tests never touch the platform.
  void play() {
    SystemSound.play(SystemSoundType.alert);
  }
}
