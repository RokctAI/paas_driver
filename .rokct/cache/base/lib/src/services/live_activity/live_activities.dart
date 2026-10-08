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
// of any kind: it throttles snapshots in memory and hands them to a
// platform sink. The check fires purely because the path contains
// 'services'.)

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'live_activity_snapshot.dart';

/// How long terminal entries stay before clearing themselves (design 6b).
class LiveActivityTimeouts {
  LiveActivityTimeouts._();

  static const Duration ended = Duration(minutes: 15);
  static const Duration error = Duration(minutes: 60);
}

/// What the controller hands the platform sink: the snapshot to draw plus
/// the rules already decided (alert or not, stale or not, timeout).
@immutable
class LiveActivityFrame {
  const LiveActivityFrame({
    required this.id,
    required this.snapshot,
    required this.alert,
    this.stale = false,
    this.first = false,
  });

  /// Stable notification id derived from `snapshot.key`.
  final int id;

  /// What to draw. When [stale] is set its subtitle already reads
  /// [LiveActivities.staleSubtitle].
  final LiveActivitySnapshot snapshot;

  /// Make a sound or vibrate. True only for the first post and for a
  /// terminal state (design 6a).
  final bool alert;

  /// No update for [LiveActivities.staleAfter].
  final bool stale;

  /// The first post for this key (iOS starts the activity, Android posts).
  final bool first;

  /// Terminal entries clear themselves after this; live ones never do.
  Duration? get timeoutAfter => switch (snapshot.state) {
        LiveActivityState.ended => LiveActivityTimeouts.ended,
        LiveActivityState.error => LiveActivityTimeouts.error,
        _ => null,
      };

  /// Can be swiped away. Terminal entries always can.
  bool get dismissible => snapshot.state.isTerminal || snapshot.dismissible;
}

/// Draws frames on one platform. comms_sdk registers the device sink from
/// its boot hook; with no sink registered [LiveActivities] is inert.
abstract class LiveActivitySink {
  Future<void> show(LiveActivityFrame frame);

  /// Remove the entry for [key] (id [id]) right away.
  Future<void> cancel(int id, String key);
}

class _Entry {
  _Entry(this.lastPosted, this.postedAt);

  LiveActivitySnapshot lastPosted;
  DateTime postedAt;
  LiveActivitySnapshot? pending;
  Timer? flushTimer;
  Timer? staleTimer;
  bool stale = false;

  void dispose() {
    flushTimer?.cancel();
    staleTimer?.cancel();
  }
}

/// The one live-activity controller every adopter talks to. It lives in
/// base_sdk because base is the package every SDK depends on: an adopter
/// (orders, delivery, lms) publishes snapshots without importing
/// comms_sdk, and comms_sdk registers the platform sink without knowing
/// the adopters.
///
/// Rules it enforces (design section 6):
/// * the same key always maps to the same id ([idFor]);
/// * alert only on the first post and on a terminal state;
/// * at most one post per key every [minInterval]: faster updates are
///   coalesced and the latest one is posted when the window opens;
///   terminal states bypass the throttle;
/// * after [staleAfter] without an update the subtitle is replaced by
///   [staleSubtitle] (the bar does not move on its own);
/// * a key the user swiped away is not re-posted until [reset].
class LiveActivities {
  LiveActivities({
    this.sink,
    DateTime Function()? now,
    this.minInterval = const Duration(seconds: 15),
    this.staleAfter = const Duration(minutes: 10),
  }) : _now = now ?? DateTime.now;

  /// The app-wide instance adopters use.
  static final LiveActivities instance = LiveActivities();

  static const String staleSubtitle = 'Updating paused, open to refresh';

  /// The platform sink, set by comms_sdk's boot hook. Null means inert.
  LiveActivitySink? sink;
  final Duration minInterval;
  final Duration staleAfter;
  final DateTime Function() _now;

  final Map<String, _Entry> _entries = <String, _Entry>{};
  final Set<String> _closed = <String>{};

  /// Stable, positive 31-bit id for [key] (FNV-1a). The same function the
  /// host adapters already use for their local-notification ids, so a
  /// scheduled reminder under the same key is replaced in place.
  static int idFor(String key) {
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  /// Whether [key] is currently showing.
  bool isActive(String key) => _entries.containsKey(key);

  /// Publish [snapshot]. Safe to call at any rate.
  Future<void> update(LiveActivitySnapshot snapshot) async {
    final key = snapshot.key;
    if (_closed.contains(key)) return;
    final entry = _entries[key];
    if (entry == null) {
      if (snapshot.state.isTerminal) {
        // Nothing live to end: a terminal state for a key never shown is
        // posted once, alerting, so the outcome is still seen.
        _closed.add(key);
        await _post(snapshot, alert: true, first: true);
        return;
      }
      final e = _Entry(snapshot, _now());
      _entries[key] = e;
      _armStale(key, e);
      await _post(snapshot, alert: true, first: true);
      return;
    }
    if (snapshot.state.isTerminal) {
      entry.dispose();
      _entries.remove(key);
      _closed.add(key);
      await _post(snapshot, alert: true);
      return;
    }
    if (!entry.stale && snapshot == (entry.pending ?? entry.lastPosted)) {
      return;
    }
    final since = _now().difference(entry.postedAt);
    if (since >= minInterval && entry.flushTimer == null) {
      await _postLive(key, entry, snapshot);
      return;
    }
    entry.pending = snapshot;
    entry.flushTimer ??= Timer(minInterval - since, () {
      entry.flushTimer = null;
      final p = entry.pending;
      if (p != null && identical(_entries[key], entry)) {
        unawaited(_postLive(key, entry, p));
      }
    });
  }

  /// Remove [key] now (the adopter's entity went away, or sign-out).
  Future<void> end(String key) async {
    _entries.remove(key)?.dispose();
    _closed.add(key);
    await _safe(() => sink?.cancel(idFor(key), key));
  }

  /// The user swiped [key] away: it ends for this entity only and the app
  /// does not re-post it (design 6b). Terminal updates are dropped too.
  void markDismissed(String key) {
    _entries.remove(key)?.dispose();
    _closed.add(key);
  }

  /// Forget that [key] ended or was dismissed, so a new activity under the
  /// same key (a re-opened order) can start again.
  void reset(String key) {
    _entries.remove(key)?.dispose();
    _closed.remove(key);
  }

  @visibleForTesting
  void clearAll() {
    for (final e in _entries.values) {
      e.dispose();
    }
    _entries.clear();
    _closed.clear();
  }

  Future<void> _postLive(
    String key,
    _Entry entry,
    LiveActivitySnapshot snapshot,
  ) async {
    entry
      ..pending = null
      ..lastPosted = snapshot
      ..postedAt = _now()
      ..stale = false;
    _armStale(key, entry);
    await _post(snapshot, alert: false);
  }

  void _armStale(String key, _Entry entry) {
    entry.staleTimer?.cancel();
    entry.staleTimer = Timer(staleAfter, () {
      if (!identical(_entries[key], entry)) return;
      entry.stale = true;
      unawaited(_post(
        entry.lastPosted.copyWith(subtitle: staleSubtitle),
        alert: false,
        stale: true,
      ));
    });
  }

  Future<void> _post(
    LiveActivitySnapshot snapshot, {
    required bool alert,
    bool stale = false,
    bool first = false,
  }) async {
    final s = sink;
    if (s == null) return;
    await _safe(() => s.show(LiveActivityFrame(
          id: idFor(snapshot.key),
          snapshot: snapshot,
          alert: alert,
          stale: stale,
          first: first,
        )));
  }

  Future<void> _safe(Future<void>? Function() body) async {
    try {
      await body();
    } catch (e) {
      // A live activity is decoration on the screen that owns the data;
      // a platform failure must never reach that screen.
      debugPrint('==> LiveActivities: $e');
    }
  }
}
