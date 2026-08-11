import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:base_sdk/src/sync/sync_engine.dart';

/// App-lifetime connectivity listener.
///
/// The widget-level subscribers (`custom_scaffold.dart`,
/// `custom_status_bar.dart`) die with their widget tree, so they cannot be
/// trusted to observe an offline -> online transition. This singleton
/// subscribes exactly once for the whole process and kicks the [SyncEngine]
/// on each regain so queued offline work drains as soon as a connection is
/// back. Started from `BaseSdkDependencies.register`.
class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService I = ConnectivityService._();

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  // Start pessimistic: the first online event then triggers a kick, which
  // is a cheap no-op when the outbox is already drained.
  bool _wasOnline = false;

  /// Idempotent; subsequent calls are no-ops.
  void start() {
    if (_subscription != null) return;
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final online = _isOnline(results);
      final regained = online && !_wasOnline;
      _wasOnline = online;
      if (regained) {
        SyncEngine().kick();
      }
    });
  }

  /// For tests and teardown only — the service normally lives as long as
  /// the process.
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _wasOnline = false;
  }

  // Same online definition as AppConnectivity.connectivity().
  bool _isOnline(List<ConnectivityResult> results) =>
      results.contains(ConnectivityResult.mobile) ||
      results.contains(ConnectivityResult.ethernet) ||
      results.contains(ConnectivityResult.wifi);
}
