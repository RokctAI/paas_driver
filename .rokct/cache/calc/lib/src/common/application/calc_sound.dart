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

// THE CALCULATOR'S OWN MUTE (Ray: "calc must have mute on itself").
//
// Every calc key press plays base_sdk's `KeySound.tap()` (tap.wav plus a
// light haptic). base_sdk gates that behind ONE fleet-wide flag
// (`LocalStorage.getKeypadSound`, default ON), but nothing in the fleet
// renders a switch for it, and flipping it would also silence the till's
// MoneyKeypad. So the calculator carries its own gate, in front of the
// fleet one: muted here silences the calculator and nothing else.
//
// Persisted through base_sdk's generic record store (`LocalStorage
// .setJson` / `getJson`, design 46e - "feature SDKs park their own small
// records in the same store"), under [CalcSound.storageKey]. DEFAULT
// UNMUTED: an absent, empty or corrupt record reads as "sound on", which
// is exactly the behaviour before this gate existed. Sign-out does not
// touch it (LocalStorage.logout never clears host records): it is a
// per-device preference, not a session one.

import 'package:base_sdk/src/services/key_sound.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:flutter/foundation.dart';

class CalcSound {
  CalcSound._();

  /// The host-record key (LocalStorage prefixes it, so it can never
  /// collide with a typed kernel key).
  static const String storageKey = 'calc_sdk.sound';

  static ValueNotifier<bool>? _muted;

  /// Whether the calculator is muted. Listenable so the header toggle
  /// redraws the moment it flips. Read from storage on first use.
  static ValueListenable<bool> get muted => _notifier;

  static bool get isMuted => _notifier.value;

  static ValueNotifier<bool> get _notifier =>
      _muted ??= ValueNotifier<bool>(_read());

  static bool _read() => LocalStorage.getJson(storageKey)?['muted'] == true;

  /// Mutes or unmutes the calculator and persists the choice.
  static Future<void> setMuted(bool value) async {
    _notifier.value = value;
    await LocalStorage.setJson(storageKey, {'muted': value});
  }

  static Future<void> toggle() => setMuted(!isMuted);

  /// The calculator's key feedback. Every calc key and memory pill calls
  /// this instead of `KeySound.tap()` directly; muted, it does nothing
  /// (no click, no haptic). Unmuted it is exactly the old call, still
  /// behind base_sdk's own fleet gate.
  static void tap() {
    if (isMuted) return;
    player();
  }

  /// What [tap] plays. Swappable so tests can count presses without the
  /// audio plugin.
  @visibleForTesting
  static void Function() player = KeySound.tap;

  /// Re-reads the persisted state (tests reset storage between cases).
  @visibleForTesting
  static void reload() {
    _muted?.value = _read();
    _muted ??= ValueNotifier<bool>(_read());
  }
}
