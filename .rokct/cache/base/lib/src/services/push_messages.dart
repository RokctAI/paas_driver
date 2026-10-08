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

import 'package:flutter/foundation.dart';

/// Handler for one push message's `data` map.
typedef PushMessageHandler = FutureOr<void> Function(
  Map<String, dynamic> data,
);

/// App-wide registry of push-message handlers, keyed by the message's
/// `data['type']`. It lives in base_sdk for the same reason
/// [LiveActivities] does: comms_sdk (the push owner) dispatches every
/// received message here without knowing the feature SDKs, and a feature
/// SDK (orders' `order_status`) registers a handler without importing
/// comms_sdk.
///
/// One handler per type; registering again replaces it. A handler that
/// throws is logged and never stops the dispatch.
class PushMessages {
  PushMessages();

  /// The app-wide instance.
  static final PushMessages instance = PushMessages();

  final Map<String, PushMessageHandler> _handlers =
      <String, PushMessageHandler>{};

  /// Handle messages whose `data['type']` is [type].
  void register(String type, PushMessageHandler handler) =>
      _handlers[type] = handler;

  void unregister(String type) => _handlers.remove(type);

  bool handles(String? type) => type != null && _handlers.containsKey(type);

  /// Run the handler for [data]'s type. Returns whether one ran.
  Future<bool> dispatch(Map<String, dynamic> data) async {
    final type = data['type']?.toString();
    final handler = type == null ? null : _handlers[type];
    if (handler == null) return false;
    try {
      await handler(data);
    } catch (e) {
      debugPrint('==> push message "$type" handler: $e');
    }
    return true;
  }
}
