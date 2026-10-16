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

// compliance-ignore-file: flutter-http-timeout
// The package:dio import is only for DioException types. Delivery goes
// through base_sdk's HttpService (dioHttp), which sets connect/receive
// timeouts centrally; no unconfigured HTTP client is created here.

import 'dart:async';

import 'package:base_sdk/base_sdk.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

/// Sends one `{cmd, payload}` to the backend. Throws on failure.
typedef TelemetrySender = Future<void> Function(
  String cmd,
  Map<String, dynamic> payload,
);

/// Thrown by the default sender while no HttpService is registered (an
/// event tracked before DI finished): the event is kept and sent later.
class TelemetryNotReady implements Exception {
  const TelemetryNotReady();

  @override
  String toString() => 'TelemetryNotReady: no HttpService registered';
}

/// Where the spool keeps its queue between app runs.
abstract class TelemetrySpoolStore {
  Map<String, dynamic>? read();
  Future<void> write(Map<String, dynamic>? record);
}

/// The default store: base_sdk [LocalStorage]'s generic JSON record API
/// (SharedPreferences), the place feature SDKs park their own small
/// records. A no-op before `LocalStorage.init`, in which case the queue
/// lives in memory only.
class LocalStorageTelemetrySpoolStore implements TelemetrySpoolStore {
  const LocalStorageTelemetrySpoolStore();

  static const String key = 'telemetry_spool';

  @override
  Map<String, dynamic>? read() => LocalStorage.getJson(key);

  @override
  Future<void> write(Map<String, dynamic>? record) =>
      LocalStorage.setJson(key, record);
}

/// telemetry_sdk's delivery policy: a [TelemetryTransport] that sends
/// online and spools offline.
///
/// Installed into base_sdk's seam by `TelemetryBootstrap.enableSpool`
/// (called from `TelemetrySdkDependencies.register`), so every
/// `TelemetryClient.track` / `logError` call in the composed app goes
/// through [deliver]:
///
/// * Online, the event is POSTed to the platform gateway
///   (`/api/v1/method/rokct.platform.api` with `{cmd, payload}`), exactly
///   what `TelemetryClient`'s default delivery does.
/// * Offline (no network per [AppConnectivity.isOnline]), or when the send
///   fails at the network level (timeout, connection error, 502/503/504),
///   the event is queued on the device instead of being lost, and
///   [deliver] returns normally so the client reports it as handed off.
/// * Any other failure (for example a control-role site rejecting the
///   tenant cmd) is rethrown, so the client's `control:` fallback still
///   runs as before.
///
/// The queue is flushed in batches of [batchSize] when connectivity comes
/// back, at start, and after any successful live send. Each queued event
/// keeps its original payload, including the timestamp it was recorded
/// at. At most [maxQueued] events are kept (oldest dropped first).
class TelemetrySpool {
  TelemetrySpool({
    TelemetrySender? send,
    Future<bool> Function()? isOnline,
    TelemetrySpoolStore? store,
    this.batchSize = 20,
    this.maxQueued = 500,
  })  : _send = send ?? _gatewaySend,
        _isOnline = isOnline ?? AppConnectivity.connectivity,
        _store = store ?? const LocalStorageTelemetrySpoolStore();

  static final TelemetrySpool instance = TelemetrySpool();

  /// Version of the persisted record.
  static const int recordVersion = 1;

  final int batchSize;
  final int maxQueued;
  final TelemetrySender _send;
  final Future<bool> Function() _isOnline;
  final TelemetrySpoolStore _store;

  List<_SpooledEvent>? _queue;
  Future<void>? _flushing;
  StreamSubscription<List<ConnectivityResult>>? _connectivity;

  /// The control-role twin of each tenant cmd, mirroring
  /// `TelemetryClient`'s own fallback.
  static const Map<String, String> _controlTwin = <String, String>{
    TelemetryClient.trackCmd: TelemetryClient.controlTrackCmd,
    TelemetryClient.cmd: TelemetryClient.controlCmd,
  };

  /// The default sender: the same gateway POST `TelemetryClient` makes
  /// without a transport. Throws [TelemetryNotReady] when no HttpService is
  /// registered yet, which [deliver] treats as "send later".
  static Future<void> _gatewaySend(
    String cmd,
    Map<String, dynamic> payload,
  ) async {
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<HttpService>()) {
      throw const TelemetryNotReady();
    }
    await getIt.get<HttpService>().client(requireAuth: true).post(
      kPlatformGatewayPath,
      data: <String, dynamic>{'cmd': cmd, 'payload': payload},
    );
  }

  /// Number of events waiting to be sent.
  int get pending => _load().length;

  /// The [TelemetryTransport] installed into `TelemetryClient.configure`.
  Future<void> deliver(String cmd, Map<String, dynamic> payload) async {
    bool online;
    try {
      online = await _isOnline();
    } catch (_) {
      online = true; // Unknown: try the send; a network error spools it.
    }
    if (!online) {
      await _enqueue(cmd, payload);
      return;
    }
    try {
      await _send(cmd, payload);
    } catch (e) {
      if (!isRetryable(e)) rethrow;
      await _enqueue(cmd, payload);
      return;
    }
    if (_load().isNotEmpty) unawaited(flush());
  }

  /// Whether [error] means "the backend could not be reached", so the
  /// event should be kept and sent later rather than given up on.
  static bool isRetryable(Object error) {
    if (error is TelemetryNotReady) return true;
    if (error is! DioException) return false;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final int? status = error.response?.statusCode;
        return status == 502 || status == 503 || status == 504;
      default:
        // cancel, badCertificate, unknown and any type a newer dio adds:
        // not a reason to keep the event.
        return false;
    }
  }

  /// A failure during a flush that should stop the flush and keep the
  /// queue: unreachable backend, or a signed-out session (401/403), which
  /// a later flush after sign-in can still deliver.
  static bool _stopsFlush(Object error) {
    if (isRetryable(error)) return true;
    if (error is DioException && error.type == DioExceptionType.badResponse) {
      final int? status = error.response?.statusCode;
      return status == 401 || status == 403;
    }
    return false;
  }

  /// Sends queued events in batches of [batchSize] until the queue is
  /// empty or the backend stops answering. One flush at a time; a caller
  /// during a flush joins it. Never throws.
  Future<void> flush() => _flushing ??= _flush().whenComplete(() {
        _flushing = null;
      });

  Future<void> _flush() async {
    try {
      if (_load().isEmpty) return;
      bool online;
      try {
        online = await _isOnline();
      } catch (_) {
        online = true;
      }
      if (!online) return;
      while (true) {
        final List<_SpooledEvent> queue = _load();
        if (queue.isEmpty) return;
        final List<_SpooledEvent> batch =
            queue.take(batchSize).toList(growable: false);
        final Set<_SpooledEvent> done = Set<_SpooledEvent>.identity();
        bool stop = false;
        for (final _SpooledEvent event in batch) {
          final bool? sent = await _sendQueued(event);
          if (sent == null) {
            stop = true;
            break;
          }
          // Sent, or rejected for good: either way it leaves the queue.
          done.add(event);
        }
        if (done.isNotEmpty) {
          queue.removeWhere(done.contains);
          await _persist();
        }
        if (stop || done.isEmpty) return;
      }
    } catch (e) {
      debugPrint('==> telemetry spool flush failed: $e');
    }
  }

  /// true = delivered, false = rejected for good (dropped), null = backend
  /// unreachable (stop the flush and keep the event).
  Future<bool?> _sendQueued(_SpooledEvent event) async {
    try {
      await _send(event.cmd, event.payload);
      return true;
    } catch (e) {
      if (_stopsFlush(e)) return null;
      final String? twin = _controlTwin[event.cmd];
      if (twin == null) return false;
      try {
        await _send(twin, event.payload);
        return true;
      } catch (e2) {
        if (_stopsFlush(e2)) return null;
        debugPrint('==> telemetry spool dropped ${event.cmd}: rejected');
        return false;
      }
    }
  }

  /// Flushes whenever connectivity comes back, and once now. Idempotent.
  void start({Stream<List<ConnectivityResult>>? connectivityChanges}) {
    if (_connectivity != null) return;
    try {
      _connectivity =
          (connectivityChanges ?? Connectivity().onConnectivityChanged)
              .listen((List<ConnectivityResult> results) {
        if (AppConnectivity.isOnline(results)) unawaited(flush());
      }, onError: (Object e) {
        debugPrint('==> telemetry spool connectivity: $e');
      });
    } catch (e) {
      debugPrint('==> telemetry spool connectivity unavailable: $e');
    }
    unawaited(flush());
  }

  Future<void> stop() async {
    await _connectivity?.cancel();
    _connectivity = null;
  }

  Future<void> _enqueue(String cmd, Map<String, dynamic> payload) async {
    final List<_SpooledEvent> queue = _load();
    queue.add(_SpooledEvent(cmd, Map<String, dynamic>.from(payload)));
    while (queue.length > maxQueued) {
      queue.removeAt(0);
    }
    await _persist();
  }

  List<_SpooledEvent> _load() {
    final List<_SpooledEvent>? loaded = _queue;
    if (loaded != null) return loaded;
    final List<_SpooledEvent> queue = <_SpooledEvent>[];
    try {
      final Map<String, dynamic>? record = _store.read();
      final dynamic events = record?['events'];
      if (record?['v'] == recordVersion && events is List) {
        for (final dynamic e in events) {
          final _SpooledEvent? event = _SpooledEvent.fromJson(e);
          if (event != null) queue.add(event);
        }
      }
    } catch (e) {
      debugPrint('==> telemetry spool: unreadable queue dropped: $e');
    }
    return _queue = queue;
  }

  Future<void> _persist() async {
    final List<_SpooledEvent> queue = _load();
    try {
      await _store.write(
        queue.isEmpty
            ? null
            : <String, dynamic>{
                'v': recordVersion,
                'events': <Map<String, dynamic>>[
                  for (final _SpooledEvent e in queue) e.toJson(),
                ],
              },
      );
    } catch (e) {
      debugPrint('==> telemetry spool: could not save queue: $e');
    }
  }

  /// Test seam: forget the in-memory queue and listeners.
  @visibleForTesting
  Future<void> reset() async {
    await stop();
    _queue = null;
    _flushing = null;
  }
}

class _SpooledEvent {
  _SpooledEvent(this.cmd, this.payload);

  final String cmd;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'cmd': cmd, 'payload': payload};

  static _SpooledEvent? fromJson(dynamic json) {
    if (json is! Map) return null;
    final dynamic cmd = json['cmd'];
    final dynamic payload = json['payload'];
    if (cmd is! String || cmd.isEmpty || payload is! Map) return null;
    return _SpooledEvent(cmd, Map<String, dynamic>.from(payload));
  }
}
