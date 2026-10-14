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

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/app_ui_keys.dart';
import 'package:base_sdk/src/models/data/count_of_notifications_data.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

import 'package:comms_sdk/src/common/local_notifications.dart';

/// Windows notification delivery, POS-parity (paas_pos main_page.dart):
/// firebase_messaging has no Windows implementation, so composed Windows
/// builds poll the notifications count over REST every 10 seconds — the
/// exact `AppConstants.refreshTime` cadence the working POS uses — and play
/// the POS notification sound (assets/audio/notification.wav, shipped by the
/// host, 2 seconds apart like the POS `playMusic()` timer) a few times on
/// each count increase. It used to loop until the count dropped or
/// [acknowledge] ran, and an app with no notification list (supacharge)
/// never did either, so it rang forever. On top of the sound, each increase
/// raises a native Windows toast via [LocalNotifications.show] (initialized
/// fail-open by [start] — see [_initToasts]) and an in-app SnackBar via
/// base_sdk's AppUiKeys.scaffoldMessenger (see [_showInAppBanner]).
///
/// Started from comms' `comms-desktop-notification-poller-boot` boot hook
/// AFTER the first frame (the hook body runs before `LocalStorage.init()`
/// and the sdk-di block in the generated main.dart, so nothing here may be
/// touched before `runApp` — the post-frame callback guarantees storage and
/// `NotificationRepositoryFacade` registration are done).
///
/// Badge: the SDK cannot import the host-installed notification provider
/// (templates/application/common/notification lands in host lib/), so the
/// poller exposes [count] / [unseenTotal] as [ValueNotifier]s; any bell UI
/// binds with a [ValueListenableBuilder] (or forwards the values into its
/// own provider) instead of the poller reaching into host state.
class DesktopNotificationPoller {
  DesktopNotificationPoller._();

  static final DesktopNotificationPoller instance =
      DesktopNotificationPoller._();

  /// POS parity: AppConstants.refreshTime in paas_pos.
  static const Duration pollInterval = Duration(seconds: 10);

  /// POS parity: the 2-second `playMusic()` loop in paas_pos main_page.dart.
  static const Duration soundLoopInterval = Duration(seconds: 2);

  /// How many times the sound plays for one count increase.
  static const int soundPlaysPerIncrease = 3;

  /// Host-shipped asset (supacharge pubspec bundles assets/audio/;
  /// AssetSource prefixes 'assets/' itself) — the same file the POS plays.
  static const String soundAsset = 'audio/notification.wav';

  /// Fixed toast id: each count increase REPLACES the previous toast in the
  /// Windows action center instead of stacking one per poll tick.
  static const int toastNotificationId = 919001;

  final AudioPlayer _player = AudioPlayer();

  Timer? _pollTimer;
  Timer? _soundTimer;
  int _soundPlays = 0;
  int? _lastTotal;
  bool _toastsReady = false;

  /// Latest polled count payload, for bell UIs that show the split
  /// notification/transaction numbers.
  final ValueNotifier<CountNotificationModel?> count = ValueNotifier(null);

  /// notification + transaction total, for simple badge bindings.
  final ValueNotifier<int> unseenTotal = ValueNotifier(0);

  bool get isRunning => _pollTimer != null;

  /// Starts the 10-second polling loop. Idempotent. Also polls once
  /// immediately so a pending count alerts without the first-tick delay.
  void start() {
    if (isRunning) {
      return;
    }
    unawaited(_initToasts());
    _pollTimer = Timer.periodic(pollInterval, (_) => _poll());
    _poll();
  }

  /// Native toast layer: no boot path called LocalNotifications.initialize()
  /// on Windows before this poller existed (the FCM hook is mobile/macOS
  /// only and no template calls it), so the poller initializes it itself.
  /// Fail-open — a host without the Windows FLN registration still gets the
  /// sound + badge, and polling is never blocked on plugin init.
  Future<void> _initToasts() async {
    try {
      await LocalNotifications.initialize();
      _toastsReady = true;
    } catch (e) {
      debugPrint('==> local notifications init skipped: $e');
    }
  }

  /// Stops polling and silences the sound loop (e.g. on logout).
  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _stopSound();
    _lastTotal = null;
  }

  /// Silences the sound loop and treats the current total as seen —
  /// call when the user opens the bell/notification surface.
  void acknowledge() {
    _stopSound();
    _lastTotal = unseenTotal.value;
  }

  Future<void> _poll() async {
    // Same auth gate as the repository's dio client (requireAuth: true):
    // no token in LocalStorage means logged out — nothing to poll.
    if (LocalStorage.getToken().isEmpty) {
      _stopSound();
      _lastTotal = null;
      return;
    }
    try {
      final response = await notificationRepo.getCount();
      response.when(
        success: (data) {
          count.value = data;
          final int total = (data.notification ?? 0) + (data.transaction ?? 0);
          unseenTotal.value = total;
          final int? last = _lastTotal;
          if (last != null && total > last) {
            // New arrivals since the previous tick: ring the POS sound,
            // raise a native toast (Windows action center) and an in-app
            // SnackBar (base_sdk 1.10.0 AppUiKeys surface).
            _startSound();
            unawaited(_showToast(total));
            _showInAppBanner(total);
          } else if (total == 0 || (last != null && total < last)) {
            // Read (count dropped) or cleared: stop ringing.
            _stopSound();
          }
          _lastTotal = total;
        },
        failure: (error, statusCode) {
          debugPrint('==> desktop notification count failure: $error');
        },
      );
    } catch (e) {
      // Fail-open: a missing DI registration or transport error must never
      // take the app down from a background timer.
      debugPrint('==> desktop notification poll skipped: $e');
    }
  }

  /// Generic on purpose: the count endpoint returns numbers, not payloads,
  /// so the toast can only announce "how many" — clicking through to the
  /// bell UI is the host's affair. Fail-open like everything else here: a
  /// missing/failed FLN init must never break the polling loop.
  Future<void> _showToast(int total) async {
    if (!_toastsReady) {
      return;
    }
    try {
      await LocalNotifications.show(
        id: toastNotificationId,
        title: '${AppHelpers.getTranslation(TrKeys.newNotifications)} '
            '($total)',
        body: '${AppHelpers.getTranslation(TrKeys.youHaveUnseenNotifications)}'
            ' ($total)',
      );
    } catch (e) {
      debugPrint('==> notification toast skipped: $e');
    }
  }

  /// In-app surface for the same count increase: a SnackBar through
  /// base_sdk's AppUiKeys.scaffoldMessenger (wired into the composed
  /// app_widget template's MaterialApp since base_sdk 1.10.0). Fail-open
  /// like the toast: apps composed before the key existed (app_widget.dart
  /// is host-owned after first compose) leave currentState null and simply
  /// keep the sound + toast + badge behavior.
  void _showInAppBanner(int total) {
    try {
      final ScaffoldMessengerState? messenger =
          AppUiKeys.scaffoldMessenger.currentState;
      if (messenger == null) {
        return;
      }
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${AppHelpers.getTranslation(TrKeys.newNotifications)} ($total)',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      // Never let a UI nicety break the polling loop.
      debugPrint('==> in-app notification banner skipped: $e');
    }
  }

  /// Rings [soundPlaysPerIncrease] times, then stops by itself. A further
  /// increase while it is ringing starts the count again.
  void _startSound() {
    _soundPlays = 0;
    if (_soundTimer != null) {
      return;
    }
    _ringOnce();
    _soundTimer = Timer.periodic(soundLoopInterval, (timer) {
      if (_soundPlays >= soundPlaysPerIncrease) {
        timer.cancel();
        _soundTimer = null;
        return;
      }
      _ringOnce();
    });
  }

  void _ringOnce() {
    _soundPlays++;
    _playSound();
  }

  void _stopSound() {
    _soundTimer?.cancel();
    _soundTimer = null;
    try {
      _player.stop();
    } catch (e) {
      debugPrint('==> notification sound stop failed: $e');
    }
  }

  Future<void> _playSound() async {
    try {
      await _player.play(AssetSource(soundAsset));
    } catch (e) {
      // A host without the audio asset still gets the badge — never crash.
      debugPrint('==> notification sound failed: $e');
    }
  }
}
