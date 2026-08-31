// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
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
