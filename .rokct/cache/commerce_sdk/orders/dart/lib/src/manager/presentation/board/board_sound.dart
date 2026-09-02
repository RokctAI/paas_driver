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
