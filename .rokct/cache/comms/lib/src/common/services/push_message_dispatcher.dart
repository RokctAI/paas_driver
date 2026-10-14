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
import 'dart:convert';

import 'package:base_sdk/base_sdk.dart' show PushMessages;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:comms_sdk/src/common/local_notifications.dart';

/// Shows a notification on the device (title, body). The seam tests use.
typedef ForegroundNotificationPresenter = Future<void> Function(
  int id,
  String title,
  String body,
);

/// Feeds received FCM messages into base_sdk's [PushMessages], so a
/// feature SDK's handler (orders' `order_status`) runs without importing
/// comms_sdk.
///
/// * Foreground messages ([FirebaseMessaging.onMessage]) and taps that
///   open the app ([FirebaseMessaging.onMessageOpenedApp],
///   [FirebaseMessaging.getInitialMessage]) are dispatched at once.
/// * A message received while the app is suspended or closed reaches
///   [firebaseMessagingBackgroundHandler] in a background isolate, where
///   no feature SDK has registered anything. Its data is queued
///   ([queueBackground]) and replayed here at start and on every resume,
///   so the handler still sees it when the app comes back.
/// * FCM shows nothing itself while the app is open. A foreground message
///   that no feature SDK claims, and that carries a title or body, is shown
///   as a local notification ([handleForeground]), so it is not lost.
class PushMessageDispatcher with WidgetsBindingObserver {
  PushMessageDispatcher({
    PushMessages? messages,
    ForegroundNotificationPresenter? presentNotification,
  })  : messages = messages ?? PushMessages.instance,
        _present = presentNotification ?? _showLocalNotification;

  static final PushMessageDispatcher instance = PushMessageDispatcher();

  /// SharedPreferences key of the background queue (JSON strings).
  static const String queueKey = 'comms_pending_push_messages';

  /// The queue keeps at most this many messages (newest kept).
  static const int maxQueued = 20;

  final PushMessages messages;
  final ForegroundNotificationPresenter _present;
  bool _started = false;

  /// Subscribe to FCM and replay the queue. Idempotent.
  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    try {
      FirebaseMessaging.onMessage.listen(
        (m) => handleForeground(
          m.data,
          title: m.notification?.title,
          body: m.notification?.body,
          messageId: m.messageId,
        ),
      );
      FirebaseMessaging.onMessageOpenedApp.listen((m) => dispatch(m.data));
    } catch (e) {
      debugPrint('==> push dispatcher: FCM unavailable: $e');
    }
    // After the first frame, so the feature SDKs' DI hooks (which run
    // after the boot hooks) have registered their handlers.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initialMessage());
      unawaited(replayQueued());
    });
  }

  Future<void> _initialMessage() async {
    try {
      final m = await FirebaseMessaging.instance.getInitialMessage();
      if (m != null) await dispatch(m.data);
    } catch (e) {
      debugPrint('==> push dispatcher: initial message: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(replayQueued());
  }

  /// Runs the handler for [data]'s type. Returns whether one ran.
  Future<bool> dispatch(Map<String, dynamic> data) async {
    if (data.isEmpty) return false;
    return messages.dispatch(Map<String, dynamic>.from(data));
  }

  /// A message received while the app is open: a type handler gets it
  /// first; otherwise its title and body are shown as a notification.
  Future<void> handleForeground(
    Map<String, dynamic> data, {
    String? title,
    String? body,
    String? messageId,
  }) async {
    final claimed = await dispatch(data);
    if (claimed) return;
    final t = title?.trim() ?? '';
    final b = body?.trim() ?? '';
    if (t.isEmpty && b.isEmpty) return;
    final id = (messageId ?? '$t|$b|${DateTime.now().microsecondsSinceEpoch}')
            .hashCode &
        0x7fffffff;
    try {
      await _present(id, t, b);
    } catch (e) {
      debugPrint('==> push dispatcher: foreground notification: $e');
    }
  }

  static Future<void> _showLocalNotification(
    int id,
    String title,
    String body,
  ) async {
    await LocalNotifications.ensureInitialized();
    await LocalNotifications.show(id: id, title: title, body: body);
  }

  /// Called from the background isolate: remember [data] for the next
  /// [replayQueued]. Never throws.
  static Future<void> queueBackground(Map<String, dynamic> data) async {
    if (data['type'] == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(queueKey) ?? <String>[];
      list.add(jsonEncode(data));
      while (list.length > maxQueued) {
        list.removeAt(0);
      }
      await prefs.setStringList(queueKey, list);
    } catch (e) {
      debugPrint('==> push dispatcher: queue: $e');
    }
  }

  /// Dispatch and clear what the background isolate queued.
  Future<void> replayQueued() async {
    List<String> list;
    try {
      final prefs = await SharedPreferences.getInstance();
      // The background isolate writes through its own instance.
      await prefs.reload();
      list = prefs.getStringList(queueKey) ?? <String>[];
      if (list.isEmpty) return;
      await prefs.remove(queueKey);
    } catch (e) {
      debugPrint('==> push dispatcher: replay: $e');
      return;
    }
    for (final raw in list) {
      try {
        final data = jsonDecode(raw);
        if (data is Map) await dispatch(Map<String, dynamic>.from(data));
      } catch (e) {
        debugPrint('==> push dispatcher: bad queued message: $e');
      }
    }
  }
}
