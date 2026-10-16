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
import 'package:flutter/foundation.dart';
import 'package:huawei_push/huawei_push.dart';

/// Raises one local notification from HMSLocalNotificationAttr [attributes].
typedef HmsLocalNotifier = Future<void> Function(
  Map<String, dynamic> attributes,
);

/// Turns incoming Huawei Push Kit messages into local notifications, the
/// HMS twin of comms_sdk's FCM handling (`PushMessageDispatcher` in the
/// foreground, `firebaseMessagingBackgroundHandler` in the background
/// isolate, `LocalNotifications.show` for the tray entry).
///
/// Push Kit hands the app a message on [Push.onMessageReceivedStream] while
/// it runs, and on the background handler [hmsBackgroundMessageHandler]
/// otherwise. Before this class nothing listened to either, so on a
/// GMS-free device a registered HMS token received messages that never
/// showed. Every received message with a title or body now raises a local
/// notification through Push Kit's own [Push.localNotification] (no second
/// notifications plugin), on the same Android channel comms'
/// `LocalNotifications.show` uses. In the foreground its data is also fed
/// to base_sdk's [PushMessages], exactly as comms does for FCM, so feature
/// SDK handlers (orders' `order_status`) run on HMS devices too.
///
/// Fail-open throughout: a notification or handler failure debugPrints.
class HmsPushMessages {
  HmsPushMessages({HmsLocalNotifier? notify, PushMessages? messages})
      : _notify = notify ?? _pushKitNotify,
        _messages = messages;

  static final HmsPushMessages instance = HmsPushMessages();

  /// The Android channel comms_sdk's `LocalNotifications.show` posts to, so
  /// HMS and FCM notifications share one entry in the app's settings.
  static const String channelId = 'general_notifications';
  static const String channelName = 'Notifications';
  static const String channelDescription = 'General notifications';

  final HmsLocalNotifier _notify;
  final PushMessages? _messages;

  PushMessages get messages => _messages ?? PushMessages.instance;

  static Future<void> _pushKitNotify(Map<String, dynamic> attributes) async {
    await Push.localNotification(attributes);
  }

  /// The local notification for one received message, or null when there
  /// is nothing to show (a silent data message). The title and body come
  /// from the message's notification part when it has one, else from the
  /// data keys `title` and `body` (or `message`), the keys the backend's
  /// push sender writes.
  static Map<String, dynamic>? localNotificationFor({
    required Map<String, dynamic> data,
    String? title,
    String? body,
    String? messageId,
  }) {
    final String shownTitle = _firstText(<Object?>[title, data['title']]);
    final String shownBody =
        _firstText(<Object?>[body, data['body'], data['message']]);
    if (shownTitle.isEmpty && shownBody.isEmpty) {
      return null;
    }
    final String idSource = (messageId != null && messageId.isNotEmpty)
        ? messageId
        : '$shownTitle|$shownBody|${DateTime.now().microsecondsSinceEpoch}';
    return <String, dynamic>{
      HMSLocalNotificationAttr.ID: '${idSource.hashCode & 0x7fffffff}',
      HMSLocalNotificationAttr.TITLE: shownTitle,
      HMSLocalNotificationAttr.MESSAGE: shownBody,
      HMSLocalNotificationAttr.BIG_TEXT: shownBody,
      HMSLocalNotificationAttr.CHANNEL_ID: channelId,
      HMSLocalNotificationAttr.CHANNEL_NAME: channelName,
      HMSLocalNotificationAttr.CHANNEL_DESCRIPTION: channelDescription,
      HMSLocalNotificationAttr.IMPORTANCE: Importance.MAX,
      HMSLocalNotificationAttr.PRIORITY: NotificationPriority.HIGH,
      HMSLocalNotificationAttr.AUTO_CANCEL: true,
      HMSLocalNotificationAttr.INVOKE_APP: true,
      HMSLocalNotificationAttr.DATA: <String, String>{
        for (final MapEntry<String, dynamic> e in data.entries)
          if (e.value != null) e.key: '${e.value}',
      },
    };
  }

  static String _firstText(List<Object?> candidates) {
    for (final Object? c in candidates) {
      final String text = c?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  /// The data payload of [message]: its map form, else its JSON string.
  static Map<String, dynamic> dataOf(RemoteMessage message) {
    final Map<String, String>? map = message.dataOfMap;
    if (map != null && map.isNotEmpty) {
      return Map<String, dynamic>.from(map);
    }
    final String? raw = message.data;
    if (raw == null || raw.isEmpty) {
      return <String, dynamic>{};
    }
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Not JSON: nothing structured to hand on.
    }
    return <String, dynamic>{};
  }

  /// Shows [message] as a local notification and, in the foreground, hands
  /// its data to [PushMessages]. Returns whether a notification was raised.
  Future<bool> handleRemoteMessage(
    RemoteMessage message, {
    bool foreground = true,
  }) =>
      handle(
        data: dataOf(message),
        title: message.notification?.title,
        body: message.notification?.body,
        messageId: message.messageId,
        foreground: foreground,
      );

  /// [handleRemoteMessage] on plain values (the test seam). In the
  /// background isolate ([foreground] false) no feature SDK has registered
  /// a [PushMessages] handler, so only the notification is raised; tapping
  /// it opens the app.
  Future<bool> handle({
    required Map<String, dynamic> data,
    String? title,
    String? body,
    String? messageId,
    bool foreground = true,
  }) async {
    bool shown = false;
    final Map<String, dynamic>? attributes = localNotificationFor(
      data: data,
      title: title,
      body: body,
      messageId: messageId,
    );
    if (attributes != null) {
      try {
        await _notify(attributes);
        shown = true;
      } catch (e) {
        debugPrint('==> HMS push local notification skipped: $e');
      }
    }
    if (foreground && data.isNotEmpty) {
      try {
        await messages.dispatch(Map<String, dynamic>.from(data));
      } catch (e) {
        debugPrint('==> HMS push message dispatch skipped: $e');
      }
    }
    return shown;
  }
}

/// Push Kit background-message entry point, registered by
/// `HmsPushBootstrap.initialize` through
/// [Push.registerBackgroundMessageHandler]. Top level with `vm:entry-point`
/// for the same reason as comms' `firebaseMessagingBackgroundHandler`: the
/// plugin starts it in a background isolate by callback handle, so AOT must
/// keep the symbol.
@pragma('vm:entry-point')
void hmsBackgroundMessageHandler(RemoteMessage message) {
  unawaited(
    HmsPushMessages.instance.handleRemoteMessage(message, foreground: false),
  );
}
