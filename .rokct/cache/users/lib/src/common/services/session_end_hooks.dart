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
// because the path contains 'services', which its is_api_or_service
// heuristic matches. The callbacks registered here do their own I/O in their
// own files, each of which rides base_sdk's traced client.)

import 'package:flutter/foundation.dart';

/// Callbacks that must run when a session ends -- sign-out, or account
/// deletion.
///
/// This exists because the work that has to happen at sign-out does not
/// all live in users_sdk. Android's Restore Credentials is the motivating
/// case: the restore key MUST be deleted when a user signs out, because
/// the platform otherwise keeps it until uninstall and the user's next
/// device would silently sign them back in. But that key is auth_sdk's
/// concern, and no SDK in this workspace depends on another SDK apart from
/// base_sdk -- adding a users_sdk -> auth_sdk edge to reach it would break
/// that rule and change composition for every consuming app.
///
/// So users_sdk owns the moment and publishes it; whoever owns the work
/// subscribes. With nothing registered this is inert, which is exactly the
/// behaviour every existing consumer already has.
///
/// Registration is idempotent by [id], so a hot restart or a double-armed
/// boot hook cannot stack duplicates.
///
/// Example, from a composed app's startup:
///
/// ```dart
/// SessionEndHooks.register(
///   'restore_credentials',
///   () => RestoreCredentialGate.clear(),
/// );
/// ```
class SessionEndHooks {
  SessionEndHooks._();

  static final Map<String, Future<void> Function()> _hooks =
      <String, Future<void> Function()>{};

  /// Subscribe [callback] to session end under [id]. Re-registering the
  /// same [id] replaces the previous callback rather than adding another.
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

  /// Run every registered callback.
  ///
  /// Each is isolated: one that throws is logged and the rest still run,
  /// because a failure to tidy up one thing must never prevent signing the
  /// user out. Callers deliberately do not surface failures here to the
  /// user -- sign-out has to feel unconditional.
  static Future<void> run() async {
    for (final entry in _hooks.entries.toList()) {
      try {
        await entry.value();
      } catch (e) {
        debugPrint('==> session end hook "${entry.key}" failed: $e');
      }
    }
  }
}
