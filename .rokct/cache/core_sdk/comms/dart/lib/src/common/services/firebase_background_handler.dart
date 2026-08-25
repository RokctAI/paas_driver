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
