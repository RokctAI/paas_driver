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

// The fleet key-feedback service — the paas_pos tender-pad sound recipe
// carried into base_sdk (calc-keypad findings, 2026-08-30):
//
//   * a TAP sound on every keypress: `assets/audio/tap.wav` (Ray's own
//     paas_pos asset, copied verbatim) played through a ROUND-ROBIN POOL
//     of pre-created audioplayers `AudioPlayer`s — paas_pos used a pool
//     of 5 so rapid keying never cuts a sound off
//     (order_calculate.dart's `_maxAudioPlayers`), and the pool size is
//     kept;
//   * a light haptic as the mobile complement (paas_pos used
//     FlutterBeep's OS click on mobile; the fleet plays the same wav
//     everywhere assets work and adds `HapticFeedback.lightImpact` on
//     touch platforms);
//   * an ERROR sound for refused actions: `assets/audio/wrong.wav`
//     (paas_pos price_info.dart's insufficient-tender feedback), with a
//     medium haptic;
//   * ONE on/off gate, persisted, DEFAULT ON — paas_pos's
//     `AppConstants.sound` flag becomes [LocalStorage.getKeypadSound].
//
// The wav files ship via base_sdk's manifest `app_assets`
// (templates/assets/audio/) so every composed host bundles them;
// `AssetSource` prefixes 'assets/' itself. Everything here fails OPEN:
// a host without the assets (or a test binding without the plugin) gets
// silence, never an exception.

import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'local_storage.dart';

class KeySound {
  KeySound._();

  /// paas_pos parity: 5 players, round-robin, so rapid keying never
  /// truncates a tap.
  static const int poolSize = 5;

  /// Host-shipped assets (base_sdk manifest `app_assets`; AssetSource
  /// prefixes 'assets/' itself).
  static const String tapAsset = 'audio/tap.wav';
  static const String errorAsset = 'audio/wrong.wav';

  static List<AudioPlayer>? _pool;
  static int _next = 0;

  /// The persisted on/off gate (default ON — paas_pos's
  /// `AppConstants.sound` default).
  static bool get enabled => LocalStorage.getKeypadSound();

  static Future<void> setEnabled(bool on) => LocalStorage.setKeypadSound(on);

  /// Key tap feedback: the tap.wav click plus a light haptic on touch
  /// platforms. Call on EVERY keypress (the paas_pos recipe).
  static void tap() {
    if (!enabled) return;
    _haptic(HapticFeedback.lightImpact);
    _play(tapAsset);
  }

  /// Refused-action feedback: the wrong.wav buzz plus a medium haptic
  /// (paas_pos played it on an insufficient-tender confirm).
  static void error() {
    if (!enabled) return;
    _haptic(HapticFeedback.mediumImpact);
    _play(errorAsset);
  }

  /// Releases the pool (a host teardown nicety; players re-create lazily).
  static Future<void> dispose() async {
    final pool = _pool;
    _pool = null;
    _next = 0;
    if (pool != null) {
      for (final player in pool) {
        try {
          await player.dispose();
        } catch (_) {
          // Fail open.
        }
      }
    }
  }

  /// Widget tests run without the audioplayers platform channel; the
  /// plugin's internal create future would surface as an unhandled zone
  /// error, so audio is skipped entirely under the test runner.
  static bool get _inTestHarness =>
      !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  static void _haptic(Future<void> Function() impact) {
    if (kIsWeb) return;
    if (Platform.isAndroid || Platform.isIOS) {
      unawaited(impact().catchError((_) {}));
    }
  }

  static void _play(String asset) {
    if (_inTestHarness) return;
    try {
      _pool ??= List.generate(poolSize, (_) => AudioPlayer());
      final player = _pool![_next];
      _next = (_next + 1) % poolSize;
      unawaited(
        player.play(AssetSource(asset)).catchError((Object _) {}),
      );
    } catch (_) {
      // Fail open — a missing asset or plugin never breaks key entry.
    }
  }
}
