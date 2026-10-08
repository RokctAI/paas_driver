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

// compliance-ignore-file: obs-flutter-trace (this file makes no network call
// of any kind: it is an in-memory callback registry. The check fires purely
// because the path contains 'services'. The callbacks registered here do
// their own work in their own files.)

import 'package:flutter/foundation.dart';

/// Callbacks that run once a sign-in has succeeded and the session is
/// established -- the counterpart of users_sdk's `SessionEndHooks`.
///
/// auth_sdk owns the moment (every login, registration and restored
/// session ends in it) and calls [run]; whoever owns follow-up work
/// subscribes from its own boot hook. It lives in base_sdk because base is
/// the only package every SDK depends on: auth_sdk can fire it and, say,
/// comms_sdk can subscribe to it without either depending on the other.
/// With nothing registered it is inert.
///
/// Registration is idempotent by id, so a hot restart or a double-armed
/// boot hook cannot stack duplicates.
///
/// ```dart
/// SessionStartHooks.register(
///   'comms_push_permission',
///   PushPermissionPrompt.onSessionStart,
/// );
/// ```
class SessionStartHooks {
  SessionStartHooks._();

  static final Map<String, Future<void> Function()> _hooks =
      <String, Future<void> Function()>{};

  /// Subscribe [callback] under [id]. Re-registering the same [id]
  /// replaces the previous callback rather than adding another.
  static void register(String id, Future<void> Function() callback) {
    _hooks[id] = callback;
  }

  /// Drop a previously registered callback.
  static void unregister(String id) {
    _hooks.remove(id);
  }

  @visibleForTesting
  static void clearAll() => _hooks.clear();

  @visibleForTesting
  static Iterable<String> get registeredIds => _hooks.keys;

  /// Run every registered callback, in registration order.
  ///
  /// Each is isolated: one that throws is logged and the rest still run.
  /// Nothing here may fail or undo the sign-in that fired it.
  static Future<void> run() async {
    for (final entry in _hooks.entries.toList()) {
      try {
        await entry.value();
      } catch (e) {
        debugPrint('==> session start hook "${entry.key}" failed: $e');
      }
    }
  }
}
