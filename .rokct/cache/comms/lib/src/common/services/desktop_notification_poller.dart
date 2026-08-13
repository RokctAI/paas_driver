import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/services/app_ui_keys.dart';
import 'package:base_sdk/src/models/data/count_of_notifications_data.dart';
import 'package:base_sdk/src/services/local_storage.dart';

import 'package:comms_sdk/src/common/local_notifications.dart';

/// Windows notification delivery, POS-parity (paas_pos main_page.dart):
/// firebase_messaging has no Windows implementation, so composed Windows
/// builds poll the notifications count over REST every 10 seconds — the
/// exact `AppConstants.refreshTime` cadence the working POS uses — and loop
/// the POS notification sound (assets/audio/notification.wav, shipped by the
/// host, played every 2 seconds like the POS `playMusic()` timer) while
/// unseen notifications exist. On top of the sound, each count INCREASE
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

  /// Host-shipped asset (supacharge pubspec bundles assets/audio/;
  /// AssetSource prefixes 'assets/' itself) — the same file the POS plays.
  static const String soundAsset = 'audio/notification.wav';

  /// Fixed toast id: each count increase REPLACES the previous toast in the
  /// Windows action center instead of stacking one per poll tick.
  static const int toastNotificationId = 919001;

  final AudioPlayer _player = AudioPlayer();

  Timer? _pollTimer;
  Timer? _soundTimer;
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
            // New arrivals since the previous tick: loop the POS sound,
            // raise a native toast (Windows action center) and an in-app
            // SnackBar (base_sdk 1.10.0 AppUiKeys surface).
            _startSound();
            unawaited(_showToast(total));
            _showInAppBanner(total);
          } else if (total == 0 || (last != null && total < last)) {
            // Read (count dropped) or cleared: stop looping.
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
        title: 'New notifications ($total)',
        body: 'You have $total unseen notification(s).',
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
          content: Text('New notifications ($total)'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      // Never let a UI nicety break the polling loop.
      debugPrint('==> in-app notification banner skipped: $e');
    }
  }

  void _startSound() {
    if (_soundTimer != null) {
      return;
    }
    _playSound();
    _soundTimer = Timer.periodic(soundLoopInterval, (_) => _playSound());
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
