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


import 'package:base_sdk/base_sdk.dart' show DemoSession, LocalStorage;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:comms_sdk/src/common/services/push_permission_prompt.dart';
import 'package:comms_sdk/src/common/services/push_permission_service.dart';

const NotificationSettings _granted = NotificationSettings(
  alert: AppleNotificationSetting.enabled,
  announcement: AppleNotificationSetting.notSupported,
  authorizationStatus: AuthorizationStatus.authorized,
  badge: AppleNotificationSetting.disabled,
  carPlay: AppleNotificationSetting.notSupported,
  lockScreen: AppleNotificationSetting.enabled,
  notificationCenter: AppleNotificationSetting.enabled,
  showPreviews: AppleShowPreviewSetting.always,
  timeSensitive: AppleNotificationSetting.notSupported,
  criticalAlert: AppleNotificationSetting.notSupported,
  sound: AppleNotificationSetting.enabled,
  providesAppNotificationSettings: AppleNotificationSetting.notSupported,
);

void main() {
  late int calls;
  NotificationSettings? answer;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    await DemoSession.instance.clear();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    PushPermissionService.resetForTest();
    calls = 0;
    answer = _granted;
    PushPermissionService.platformRequestOverride =
        ({required bool sound, required bool alert, required bool badge}) async {
      calls++;
      return answer;
    };
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    PushPermissionService.resetForTest();
  });

  test('asks on the first sign-in and records it', () async {
    await PushPermissionPrompt.onSessionStart();
    expect(calls, 1);
    expect(PushPermissionPrompt.alreadyAsked, isTrue);
  });

  test('does not ask again once asked', () async {
    await PushPermissionPrompt.onSessionStart();
    await PushPermissionPrompt.onSessionStart();
    expect(calls, 1);
  });

  test('the flag survives a restart (it is persisted)', () async {
    await PushPermissionPrompt.onSessionStart();
    await LocalStorage.init();
    await PushPermissionPrompt.onSessionStart();
    expect(calls, 1);
  });

  test('never asks in a demo session, and leaves the flag unset', () async {
    await DemoSession.instance.activate();
    await PushPermissionPrompt.onSessionStart();
    expect(calls, 0);
    expect(PushPermissionPrompt.alreadyAsked, isFalse);

    await DemoSession.instance.clear();
    await PushPermissionPrompt.onSessionStart();
    expect(calls, 1);
  });

  test('a failed request is retried at the next sign-in', () async {
    answer = null;
    await PushPermissionPrompt.onSessionStart();
    expect(PushPermissionPrompt.alreadyAsked, isFalse);

    answer = _granted;
    await PushPermissionPrompt.onSessionStart();
    expect(calls, 2);
    expect(PushPermissionPrompt.alreadyAsked, isTrue);
  });

  test('an unsupported platform never asks and never records', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    await PushPermissionPrompt.onSessionStart();
    expect(calls, 0);
    expect(PushPermissionPrompt.alreadyAsked, isFalse);
  });
}
