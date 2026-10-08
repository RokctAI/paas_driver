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

// compliance-ignore-file: obs-flutter-trace (no network call: it draws
// LiveActivityFrames with the device's notification APIs.)

import 'dart:async';

import 'package:base_sdk/base_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:live_activities/live_activities.dart' as ios;

import '../local_notifications.dart';

/// Text rules shared by every rendering (design 1a, 1c-ii).
class LiveActivityText {
  LiveActivityText._();

  static String clock(DateTime t) {
    final l = t.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}';
  }

  /// "Arrives 12:52", "Arrives about 12:55", "Now" while ending, empty for
  /// a terminal state or without an end time. Always a clock time, never
  /// "in 11 min", so the text cannot go stale between updates.
  static String endLabel(LiveActivitySnapshot s) {
    if (s.state.isTerminal) return '';
    if (s.state == LiveActivityState.ending) return 'Now';
    final at = s.endsAt;
    if (at == null) return '';
    final about = s.endsAtApproximate ? 'about ' : '';
    final label = s.endsAtLabel.isEmpty ? '' : '${s.endsAtLabel} ';
    return '$label$about${clock(at)}';
  }

  /// Android 15 and older: the end time joins the title ("On the way ·
  /// arrives 12:52"). A countdown is drawn by the chronometer instead.
  static String compactTitle(LiveActivitySnapshot s) {
    if (s.countdown) return s.title;
    final end = endLabel(s);
    if (end.isEmpty) return s.title;
    return '${s.title} · ${end[0].toLowerCase()}${end.substring(1)}';
  }

  /// Android 15 and older: "Stage 4 of 5" takes the segments' place.
  static String compactBody(LiveActivitySnapshot s) {
    final stage = s.state.isTerminal ? '' : s.stageLabel;
    if (stage.isEmpty) return s.subtitle;
    if (s.subtitle.isEmpty) return stage;
    return '$stage · ${s.subtitle}';
  }
}

/// The device [LiveActivitySink], registered into base_sdk's
/// [LiveActivities] by comms_sdk's `comms-live-activity-sink` boot hook.
///
/// * Android 16+ (API 36): asks the host's `rokct/live_updates` method
///   channel to draw a promoted `Notification.ProgressStyle` (segments,
///   points, tracker icon). The channel is scaffolded in
///   `templates/native/android/`; while a host has not wired it the call
///   answers `MissingPluginException` and the sink falls back.
/// * Android 15 and older, and the fallback: an ongoing
///   flutter_local_notifications entry on the "Live updates" channel with
///   a progress bar, `onlyAlertOnce`, a chronometer for countdowns and
///   `timeoutAfter` for terminal states.
/// * iOS: an ActivityKit Live Activity through `live_activities`, drawn by
///   the SwiftUI widget scaffolded in `templates/native/ios/`. Needs the
///   `LIVE_ACTIVITY_APP_GROUP` define; without it iOS is skipped.
class DeviceLiveActivitySink implements LiveActivitySink {
  DeviceLiveActivitySink({
    MethodChannel? promotedChannel,
    ios.LiveActivities? liveActivities,
  })  : _promoted = promotedChannel ?? const MethodChannel(channelName),
        _ios = liveActivities;

  static const String channelName = 'rokct/live_updates';
  static const String androidChannelId = 'live_updates';
  static const String androidChannelName = 'Live updates';

  /// App group shared with the iOS widget extension.
  static const String iosAppGroup = String.fromEnvironment(
    'LIVE_ACTIVITY_APP_GROUP',
  );

  final MethodChannel _promoted;
  ios.LiveActivities? _ios;
  Future<bool>? _iosReady;
  bool _promotedUnavailable = false;
  final Map<String, String> _iosIds = <String, String>{};

  @override
  Future<void> show(LiveActivityFrame frame) async {
    if (kIsWeb) return;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        if (await _showPromoted(frame)) return;
        await LocalNotifications.ensureInitialized();
        await LocalNotifications.plugin.show(
          frame.id,
          LiveActivityText.compactTitle(frame.snapshot),
          LiveActivityText.compactBody(frame.snapshot),
          NotificationDetails(android: androidDetails(frame)),
          payload: frame.snapshot.deepLink,
        );
      case TargetPlatform.iOS:
        await _showIos(frame);
      default:
        return;
    }
  }

  @override
  Future<void> cancel(int id, String key) async {
    if (kIsWeb) return;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final activityId = _iosIds.remove(key);
      if (activityId != null) await _ios?.endActivity(activityId);
      return;
    }
    if (defaultTargetPlatform != TargetPlatform.android) return;
    if (!_promotedUnavailable) {
      try {
        await _promoted.invokeMethod<void>('cancel', {'id': id});
      } on MissingPluginException {
        _promotedUnavailable = true;
      }
    }
    await LocalNotifications.ensureInitialized();
    await LocalNotifications.plugin.cancel(id);
  }

  /// Android 16 ProgressStyle through the host channel. False when the
  /// host has no channel or the OS is older (the native side answers
  /// false below API 36), so the caller falls back to a plain bar.
  Future<bool> _showPromoted(LiveActivityFrame frame) async {
    if (_promotedUnavailable) return false;
    try {
      final drawn = await _promoted.invokeMethod<bool>('show', {
        ...frame.snapshot.toMap(),
        'id': frame.id,
        'alert': frame.alert,
        'stale': frame.stale,
        'dismissible': frame.dismissible,
        'timeoutAfterMs': frame.timeoutAfter?.inMilliseconds,
        'endLabel': LiveActivityText.endLabel(frame.snapshot),
        'channelId': androidChannelId,
        'channelName': androidChannelName,
        'colorDone': LiveActivityTokens.segmentDone.toARGB32(),
        'colorEnded': LiveActivityTokens.ended.toARGB32(),
        'colorError': LiveActivityTokens.error.toARGB32(),
      });
      return drawn ?? false;
    } on MissingPluginException {
      _promotedUnavailable = true;
      return false;
    }
  }

  /// The Android 15-and-older rendering (design 1c-ii) as notification
  /// details. Public for tests.
  @visibleForTesting
  static AndroidNotificationDetails androidDetails(LiveActivityFrame frame) {
    final s = frame.snapshot;
    final colour = switch (s.state) {
      LiveActivityState.ended => LiveActivityTokens.ended,
      LiveActivityState.error => LiveActivityTokens.error,
      _ => LiveActivityTokens.segmentDone,
    };
    final endsAt = s.endsAt;
    final chronometer = s.countdown && endsAt != null && !s.state.isTerminal;
    final progress = s.progress;
    return AndroidNotificationDetails(
      androidChannelId,
      androidChannelName,
      channelDescription:
          'Orders on their way, deliveries and classes about to start',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      category: AndroidNotificationCategory.progress,
      ongoing: !frame.dismissible,
      autoCancel: false,
      onlyAlertOnce: !frame.alert,
      silent: !frame.alert,
      showProgress:
          s.showProgress && (progress != null || !s.state.isTerminal),
      maxProgress: 100,
      progress: ((progress ?? 0) * 100).round(),
      indeterminate:
          s.showProgress && progress == null && !s.state.isTerminal,
      usesChronometer: chronometer,
      chronometerCountDown: chronometer,
      when: chronometer ? endsAt.millisecondsSinceEpoch : null,
      showWhen: chronometer,
      timeoutAfter: frame.timeoutAfter?.inMilliseconds,
      color: colour,
      subText: s.appName.isEmpty ? null : s.appName,
      actions: [
        for (final a in s.actions)
          AndroidNotificationAction(a.id, a.label, showsUserInterface: true),
      ],
    );
  }

  Future<bool> _ensureIos() => _iosReady ??= () async {
        if (iosAppGroup.isEmpty) return false;
        final plugin = _ios ??= ios.LiveActivities();
        await plugin.init(appGroupId: iosAppGroup);
        return plugin.areActivitiesEnabled();
      }();

  Future<void> _showIos(LiveActivityFrame frame) async {
    if (!await _ensureIos()) return;
    final plugin = _ios!;
    final key = frame.snapshot.key;
    final data = <String, dynamic>{
      ...frame.snapshot.toMap(),
      'stale': frame.stale,
      'endLabel': LiveActivityText.endLabel(frame.snapshot),
    }..removeWhere((_, v) => v == null);
    final existing = _iosIds[key];
    if (existing == null) {
      final created = await plugin.createActivity(
        key,
        data,
        staleIn: const Duration(minutes: 10),
      );
      if (created != null) _iosIds[key] = created;
    } else {
      await plugin.updateActivity(existing, data);
    }
    final timeout = frame.timeoutAfter;
    final activityId = _iosIds[key];
    if (timeout != null && activityId != null) {
      // Terminal: the final state stays for its timeout, then ends.
      _iosIds.remove(key);
      unawaited(Future<void>.delayed(timeout, () async {
        try {
          await plugin.endActivity(activityId);
        } catch (e) {
          debugPrint('==> DeviceLiveActivitySink: $e');
        }
      }));
    }
  }
}
