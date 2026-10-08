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

import 'package:flutter/foundation.dart';

/// Which surface a live activity belongs to. The platform sink uses it to
/// pick the iOS widget layout; Android draws every kind the same way.
enum LiveActivityKind { orderTracking, driverDelivery, classCountdown }

/// Where the activity is in its life (design section 1b). "Stale" is not a
/// state: it is a flag on the frame the controller posts.
enum LiveActivityState {
  /// Posted or updating. The controller alerts only on the first post.
  live,

  /// The last stage before the terminal event: still silent, and the end
  /// time reads "Now".
  ending,

  /// Terminal success (delivered, class started). Alerts once, becomes
  /// dismissible and clears itself after [LiveActivityTimeouts.ended].
  ended,

  /// Terminal failure (cancelled, failed). Alerts once, the bar freezes,
  /// dismissible, clears after [LiveActivityTimeouts.error].
  error;

  bool get isTerminal => this == ended || this == error;
}

/// The tracker glyph that rides the bar (design section 6c). The same
/// asset key is used on Android and iOS.
enum LiveActivityTracker {
  none,
  car,
  scooter,
  parcel,
  cap;

  /// Asset key shared by both platforms (`live_tracker_car`, ...).
  String get assetKey => 'live_tracker_$name';
}

/// One action button. At most two per activity, neither destructive: each
/// only opens [deepLink] in the app.
@immutable
class LiveActivityAction {
  const LiveActivityAction({
    required this.id,
    required this.label,
    required this.deepLink,
  });

  final String id;
  final String label;
  final String deepLink;

  Map<String, Object?> toMap() =>
      {'id': id, 'label': label, 'deepLink': deepLink};

  @override
  bool operator ==(Object other) =>
      other is LiveActivityAction &&
      other.id == id &&
      other.label == label &&
      other.deepLink == deepLink;

  @override
  int get hashCode => Object.hash(id, label, deepLink);
}

/// One immutable snapshot of a live activity (design section 1a). An
/// adopter builds a new one on every change and hands it to
/// `LiveActivities.update`; the platform sink decides how to draw it. The
/// design never depends on a field one platform cannot show.
@immutable
class LiveActivitySnapshot {
  LiveActivitySnapshot({
    required this.key,
    required this.kind,
    required this.title,
    this.subtitle = '',
    double? progress,
    this.segments = const <String>[],
    this.trackerIcon = LiveActivityTracker.none,
    this.endsAt,
    this.endsAtLabel = '',
    this.endsAtApproximate = false,
    this.countdown = false,
    this.deepLink,
    this.actions = const <LiveActivityAction>[],
    this.state = LiveActivityState.live,
    this.dismissible = true,
    this.appName = '',
    this.showProgress = true,
  })  : assert(key.isNotEmpty, 'key must be stable and non-empty'),
        assert(actions.length <= 2, 'at most two actions (design 1a)'),
        progress = progress?.clamp(0.0, 1.0).toDouble();

  /// Stable identity, e.g. `order:123`. The same key always maps to the
  /// same notification id, so a live activity can never stack.
  final String key;
  final LiveActivityKind kind;

  /// The current stage, three words or fewer.
  final String title;

  /// Who and where, one line.
  final String subtitle;

  /// 0 to 1, or null for indeterminate. Comes from real progress, never
  /// from time passing: when it is unknown the adopter keeps the last one.
  final double? progress;

  /// One label per stage. Empty for a plain bar (class countdown).
  final List<String> segments;
  final LiveActivityTracker trackerIcon;

  /// Absolute end time. Drawn as a clock time ("Arrives 12:52"), or as a
  /// system-drawn countdown when [countdown] is set.
  final DateTime? endsAt;

  /// The word before the end time: "Arrives", "Due", "Starts".
  final String endsAtLabel;

  /// True while the end time is an estimate ("about 12:55").
  final bool endsAtApproximate;

  /// Draw [endsAt] as a system countdown (Android chronometer, iOS timer
  /// text) instead of a clock time.
  final bool countdown;

  /// Tapping the body opens this in-app route.
  final String? deepLink;
  final List<LiveActivityAction> actions;
  final LiveActivityState state;

  /// False for an entry that must not be swiped away while live (the
  /// driver's foreground-service entry). Terminal states are always
  /// dismissible.
  final bool dismissible;

  /// Header line ("Marketplace"). Empty lets the sink use the app label.
  final String appName;

  /// False draws no bar at all (the driver's "Online · waiting for
  /// orders" entry). A null [progress] with the bar shown is indeterminate.
  final bool showProgress;

  /// The segment the tracker is in (0-based), or null without segments.
  int? get activeSegment {
    if (segments.isEmpty) return null;
    final p = progress ?? 0;
    if (p >= 1) return segments.length - 1;
    return (p * segments.length).floor().clamp(0, segments.length - 1);
  }

  /// "Stage 4 of 5": replaces the segments where the platform cannot draw
  /// them (Android 15 and older).
  String get stageLabel {
    final a = activeSegment;
    if (a == null) return '';
    return 'Stage ${a + 1} of ${segments.length}';
  }

  LiveActivitySnapshot copyWith({
    String? title,
    String? subtitle,
    double? progress,
    LiveActivityState? state,
    DateTime? endsAt,
    bool? endsAtApproximate,
    bool? dismissible,
    List<LiveActivityAction>? actions,
  }) =>
      LiveActivitySnapshot(
        key: key,
        kind: kind,
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        progress: progress ?? this.progress,
        segments: segments,
        trackerIcon: trackerIcon,
        endsAt: endsAt ?? this.endsAt,
        endsAtLabel: endsAtLabel,
        endsAtApproximate: endsAtApproximate ?? this.endsAtApproximate,
        countdown: countdown,
        deepLink: deepLink,
        actions: actions ?? this.actions,
        state: state ?? this.state,
        dismissible: dismissible ?? this.dismissible,
        appName: appName,
        showProgress: showProgress,
      );

  /// Flat map for platform channels and the iOS widget's content state.
  Map<String, Object?> toMap() => <String, Object?>{
        'key': key,
        'kind': kind.name,
        'title': title,
        'subtitle': subtitle,
        'progress': progress,
        'segments': segments,
        'activeSegment': activeSegment,
        'trackerIcon': trackerIcon.assetKey,
        'endsAtMs': endsAt?.millisecondsSinceEpoch,
        'endsAtLabel': endsAtLabel,
        'endsAtApproximate': endsAtApproximate,
        'countdown': countdown,
        'deepLink': deepLink,
        'actions': [for (final a in actions) a.toMap()],
        'state': state.name,
        'dismissible': dismissible,
        'appName': appName,
        'showProgress': showProgress,
      };

  @override
  bool operator ==(Object other) =>
      other is LiveActivitySnapshot &&
      other.key == key &&
      other.kind == kind &&
      other.title == title &&
      other.subtitle == subtitle &&
      other.progress == progress &&
      listEquals(other.segments, segments) &&
      other.trackerIcon == trackerIcon &&
      other.endsAt == endsAt &&
      other.endsAtLabel == endsAtLabel &&
      other.endsAtApproximate == endsAtApproximate &&
      other.countdown == countdown &&
      other.deepLink == deepLink &&
      listEquals(other.actions, actions) &&
      other.state == state &&
      other.dismissible == dismissible &&
      other.appName == appName &&
      other.showProgress == showProgress;

  @override
  int get hashCode => Object.hash(
        key,
        kind,
        title,
        subtitle,
        progress,
        Object.hashAll(segments),
        trackerIcon,
        endsAt,
        endsAtLabel,
        endsAtApproximate,
        countdown,
        deepLink,
        Object.hashAll(actions),
        state,
        dismissible,
        appName,
        showProgress,
      );
}
