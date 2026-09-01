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


// compliance-ignore-file: obs-flutter-trace
// False positive: this file makes no outgoing HTTP calls — it is the FCM
// background-isolate entry point (native messaging plugin callback) and only
// guards Firebase.initializeApp(). Flagged solely because its path contains
// 'services'; there is no request to stamp with a trace id.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// FCM background-message entry point, owned by comms_sdk (the push owner).
///
/// Declared in comms' manifest `boot_hooks` as the handler passed to
/// `FirebaseMessaging.onBackgroundMessage(...)` in every composed main.dart.
/// It must be a TOP-LEVEL function: the background isolate invokes it by
/// entry-point reference, so a host app's private `_firebaseMessagingBackgroundHandler`
/// (the retired paas_manager/paas_driver hand-written form) can never be
/// reached from an injected hook body — which is exactly why this lives here
/// as package code instead (manager migration M5).
///
/// The `vm:entry-point` pragma keeps the symbol alive through AOT
/// tree-shaking: nothing references it at Dart call sites in release builds,
/// only the native messaging plugin does.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // The background isolate boots without the app's Firebase state; guard the
  // init so a hot main-isolate handoff doesn't trip duplicate-app.
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
}
