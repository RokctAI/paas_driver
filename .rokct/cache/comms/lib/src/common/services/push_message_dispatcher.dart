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
class PushMessageDispatcher with WidgetsBindingObserver {
  PushMessageDispatcher({PushMessages? messages})
      : messages = messages ?? PushMessages.instance;

  static final PushMessageDispatcher instance = PushMessageDispatcher();

  /// SharedPreferences key of the background queue (JSON strings).
  static const String queueKey = 'comms_pending_push_messages';

  /// The queue keeps at most this many messages (newest kept).
  static const int maxQueued = 20;

  final PushMessages messages;
  bool _started = false;

  /// Subscribe to FCM and replay the queue. Idempotent.
  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    try {
      FirebaseMessaging.onMessage.listen((m) => dispatch(m.data));
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

  Future<void> dispatch(Map<String, dynamic> data) async {
    if (data.isEmpty) return;
    await messages.dispatch(Map<String, dynamic>.from(data));
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
