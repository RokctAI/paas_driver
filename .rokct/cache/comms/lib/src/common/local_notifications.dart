// Copyright (c) 2026 RokctAI
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


import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotifications {
  /// Windows toast attribution. The SDK is app-agnostic, so the display
  /// name and AppUserModelID come from compile-time defines with neutral
  /// defaults — hosts brand the toast with
  /// `--dart-define=APP_NAME=Supacharge --dart-define=WINDOWS_AUMID=Rokct.Supacharge`.
  /// Works unpackaged (no MSIX identity needed): flutter_local_notifications
  /// registers the AUMID/GUID pair itself. MSIX packaging only improves
  /// attribution (real app icon, notification settings entry) and can be
  /// added host-side later without touching this file.
  static const String windowsAppName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Rokct',
  );
  static const String windowsAppUserModelId = String.fromEnvironment(
    'WINDOWS_AUMID',
    defaultValue: 'Rokct.CommsSdk',
  );

  /// Identifies the notification activation callback (COM registration).
  /// Generated once for comms_sdk and hardcoded on purpose: Windows keys the
  /// registration by this value, so it must stay stable across releases —
  /// changing it orphans previously registered activations. Do NOT rotate.
  static const String windowsNotificationGuid =
      '911643dc-6203-4da4-bb32-b467d98fac8f';

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    const WindowsInitializationSettings initializationSettingsWindows =
        WindowsInitializationSettings(
          appName: windowsAppName,
          appUserModelId: windowsAppUserModelId,
          guid: windowsNotificationGuid,
        );
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
          windows: initializationSettingsWindows,
        );
    await _notificationsPlugin.initialize(initializationSettings);
  }

  /// Shows an immediate notification on any initialized platform
  /// (Android/iOS/Windows). Callers are expected to wrap this fail-open —
  /// it throws if [initialize] has not run on this platform.
  static Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    await _notificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'general_notifications',
          'Notifications',
          channelDescription: 'General notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        windows: WindowsNotificationDetails(),
      ),
    );
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // Only schedule if the date is in the future
    if (scheduledDate.isBefore(DateTime.now())) return;

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'todo_reminders',
          'Todo Reminders',
          channelDescription: 'Reminders for your tasks',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
