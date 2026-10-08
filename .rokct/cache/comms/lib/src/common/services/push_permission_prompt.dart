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
// False positive: this file makes no outgoing HTTP calls. It reads and
// writes one local flag and hands the OS prompt to PushPermissionService.
// Flagged solely because its path contains 'services'.

import 'package:base_sdk/base_sdk.dart';
import 'package:flutter/foundation.dart';

import 'push_permission_service.dart';

/// Asks for the OS notification permission once, right after the first
/// successful sign-in on this install.
///
/// Registered against base_sdk's `SessionStartHooks` by comms' own boot
/// hook, so every app that composes comms_sdk asks, and an app that does
/// not compose it never does. auth_sdk fires the hooks; it knows nothing
/// about comms.
///
/// * Demo sessions ([DemoSession.demoActive]: the guided tour or a
///   server-marked demo account) never ask and never set the flag, so the
///   real account that signs in afterwards is still asked.
/// * The flag is set only once the OS was actually asked (a non-null
///   result). An unsupported platform or a failed request leaves it unset,
///   so the next sign-in tries again.
/// * The flag is per install, not per account: the OS permission is per
///   install too.
class PushPermissionPrompt {
  PushPermissionPrompt._();

  /// The `SessionStartHooks` id this SDK registers under.
  static const String hookId = 'comms_push_permission';

  /// LocalStorage JSON key holding `{'asked': true}` once asked.
  static const String storageKey = 'comms.push_permission';

  /// True once this install has shown the OS notification prompt.
  static bool get alreadyAsked =>
      LocalStorage.getJson(storageKey)?['asked'] == true;

  /// The session-start hook body. Never throws.
  static Future<void> onSessionStart() async {
    try {
      if (DemoSession.demoActive || alreadyAsked) return;
      final settings = await PushPermissionService.request();
      if (settings != null) {
        await LocalStorage.setJson(storageKey, <String, dynamic>{
          'asked': true,
        });
      }
    } catch (e) {
      debugPrint('==> push permission prompt skipped: $e');
    }
  }
}
