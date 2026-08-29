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


import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/sync/sync_engine.dart';

/// App-lifetime connectivity listener.
///
/// The widget-level subscribers (`custom_scaffold.dart`,
/// `custom_status_bar.dart`) die with their widget tree, so they cannot be
/// trusted to observe an offline -> online transition. This singleton
/// subscribes exactly once for the whole process and kicks the [SyncEngine]
/// on each regain so queued offline work drains as soon as a connection is
/// back. A regain only counts once the backend actually answers
/// ([AppConnectivity.backendAvailability]) — a radio-only regain (Wi-Fi
/// without internet, backend down) must not burn the outbox's retry
/// attempts. Started from `BaseSdkDependencies.register`.
class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService I = ConnectivityService._();

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Backend reachability probe consulted on each regain before the drain
  /// kick. Production default is [AppConnectivity.backendAvailability]
  /// (on-demand only — never polled); tests substitute a stub.
  @visibleForTesting
  Future<bool> Function() backendProbe = AppConnectivity.backendAvailability;

  /// What a backend-confirmed regain triggers. Production default drains
  /// the outbox; tests substitute a recorder.
  @visibleForTesting
  Future<void> Function() onBackendRegained = () => SyncEngine().kick();

  // Start pessimistic: the first online event then triggers a kick, which
  // is a cheap no-op when the outbox is already drained.
  bool _wasOnline = false;

  /// Idempotent; subsequent calls are no-ops.
  void start() {
    if (_subscription != null) return;
    _subscription =
        Connectivity().onConnectivityChanged.listen(handleConnectivityChange);
  }

  /// The subscription body, callable directly from tests (the plugin's
  /// event stream is not mockable the way its method channel is).
  @visibleForTesting
  Future<void> handleConnectivityChange(List<ConnectivityResult> results) async {
    final online = _isOnline(results);
    final regained = online && !_wasOnline;
    _wasOnline = online;
    // Device connectivity back is necessary but not sufficient: only kick
    // the drain once the backend answers, so queued ops don't fail against
    // a dead backend and march toward OutboxStatus.dead.
    if (regained && await backendProbe()) {
      await onBackendRegained();
    }
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
