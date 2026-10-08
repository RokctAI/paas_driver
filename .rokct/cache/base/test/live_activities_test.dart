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

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:base_sdk/src/services/live_activity/live_activities.dart';
import 'package:base_sdk/src/services/live_activity/live_activity_snapshot.dart';

class _RecordingSink implements LiveActivitySink {
  final frames = <LiveActivityFrame>[];
  final cancelled = <String>[];

  @override
  Future<void> show(LiveActivityFrame frame) async => frames.add(frame);

  @override
  Future<void> cancel(int id, String key) async => cancelled.add(key);
}

LiveActivitySnapshot _snap({
  String title = 'On the way',
  double progress = 0.5,
  LiveActivityState state = LiveActivityState.live,
  String key = 'order:1',
}) =>
    LiveActivitySnapshot(
      key: key,
      kind: LiveActivityKind.orderTracking,
      title: title,
      subtitle: 'Thabo · 2.1 km away',
      progress: progress,
      segments: const ['Placed', 'Preparing', 'Picked up', 'On the way', 'Arriving'],
      trackerIcon: LiveActivityTracker.car,
      state: state,
    );

void main() {
  group('LiveActivitySnapshot', () {
    test('value equality and clamped progress', () {
      expect(_snap(), _snap());
      expect(_snap().hashCode, _snap().hashCode);
      expect(_snap(progress: 0.4) == _snap(progress: 0.5), isFalse);
      expect(_snap(progress: 3).progress, 1.0);
    });

    test('active segment and stage label', () {
      expect(_snap(progress: 0).stageLabel, 'Stage 1 of 5');
      expect(_snap(progress: 0.62).stageLabel, 'Stage 4 of 5');
      expect(_snap(progress: 1).activeSegment, 4);
      final plain = LiveActivitySnapshot(
        key: 'class:1',
        kind: LiveActivityKind.classCountdown,
        title: 'Maths',
      );
      expect(plain.activeSegment, isNull);
      expect(plain.stageLabel, '');
    });
  });

  group('LiveActivities', () {
    test('same key maps to the same stable id', () {
      expect(LiveActivities.idFor('order:1'), LiveActivities.idFor('order:1'));
      expect(LiveActivities.idFor('order:1'),
          isNot(LiveActivities.idFor('order:2')));
      expect(LiveActivities.idFor('order:1'), greaterThanOrEqualTo(0));
    });

    test('alerts on the first post only, then silent', () {
      fakeAsync((async) {
        final sink = _RecordingSink();
        final c = LiveActivities(sink: sink, now: async.getClock(DateTime(2026)).now);
        c.update(_snap(progress: 0.1));
        async.elapse(const Duration(seconds: 20));
        c.update(_snap(progress: 0.2));
        async.flushMicrotasks();
        expect(sink.frames.map((f) => f.alert), [true, false]);
        expect(sink.frames.first.first, isTrue);
        expect(sink.frames.map((f) => f.id).toSet().length, 1);
      });
    });

    test('throttles to one post per 15s and posts the latest', () {
      fakeAsync((async) {
        final sink = _RecordingSink();
        final c = LiveActivities(sink: sink, now: async.getClock(DateTime(2026)).now);
        c.update(_snap(progress: 0.1));
        async.elapse(const Duration(seconds: 2));
        c.update(_snap(progress: 0.2));
        c.update(_snap(progress: 0.3));
        async.elapse(const Duration(seconds: 5));
        expect(sink.frames, hasLength(1));
        async.elapse(const Duration(seconds: 8));
        expect(sink.frames, hasLength(2));
        expect(sink.frames.last.snapshot.progress, 0.3);
      });
    });

    test('identical snapshots are not re-posted', () {
      fakeAsync((async) {
        final sink = _RecordingSink();
        final c = LiveActivities(sink: sink, now: async.getClock(DateTime(2026)).now);
        c.update(_snap());
        async.elapse(const Duration(seconds: 30));
        c.update(_snap());
        async.flushMicrotasks();
        expect(sink.frames, hasLength(1));
      });
    });

    test('terminal state bypasses the throttle, alerts, and closes the key', () {
      fakeAsync((async) {
        final sink = _RecordingSink();
        final c = LiveActivities(sink: sink, now: async.getClock(DateTime(2026)).now);
        c.update(_snap());
        async.elapse(const Duration(seconds: 1));
        c.update(_snap(title: 'Delivered 12:51', progress: 1, state: LiveActivityState.ended));
        async.flushMicrotasks();
        expect(sink.frames, hasLength(2));
        final last = sink.frames.last;
        expect(last.alert, isTrue);
        expect(last.timeoutAfter, LiveActivityTimeouts.ended);
        expect(last.dismissible, isTrue);
        c.update(_snap(progress: 0.9));
        async.elapse(const Duration(minutes: 20));
        expect(sink.frames, hasLength(2));
      });
    });

    test('error clears after 60 min', () {
      final f = LiveActivityFrame(
        id: 1,
        snapshot: _snap(state: LiveActivityState.error),
        alert: true,
      );
      expect(f.timeoutAfter, LiveActivityTimeouts.error);
      expect(
        LiveActivityFrame(id: 1, snapshot: _snap(), alert: false).timeoutAfter,
        isNull,
      );
    });

    test('goes stale after 10 min without updates', () {
      fakeAsync((async) {
        final sink = _RecordingSink();
        final c = LiveActivities(sink: sink, now: async.getClock(DateTime(2026)).now);
        c.update(_snap());
        async.elapse(const Duration(minutes: 9));
        expect(sink.frames, hasLength(1));
        async.elapse(const Duration(minutes: 2));
        expect(sink.frames, hasLength(2));
        expect(sink.frames.last.stale, isTrue);
        expect(sink.frames.last.alert, isFalse);
        expect(sink.frames.last.snapshot.subtitle, LiveActivities.staleSubtitle);
        expect(sink.frames.last.snapshot.progress, 0.5);
        // The same data arriving again clears the stale subtitle.
        c.update(_snap());
        async.flushMicrotasks();
        expect(sink.frames.last.stale, isFalse);
        expect(sink.frames.last.snapshot.subtitle, 'Thabo · 2.1 km away');
      });
    });

    test('a dismissed key is not re-posted until reset', () {
      fakeAsync((async) {
        final sink = _RecordingSink();
        final c = LiveActivities(sink: sink, now: async.getClock(DateTime(2026)).now);
        c.update(_snap());
        c.markDismissed('order:1');
        async.elapse(const Duration(minutes: 1));
        c.update(_snap(progress: 0.8));
        async.elapse(const Duration(minutes: 20));
        expect(sink.frames, hasLength(1));
        c.reset('order:1');
        c.update(_snap(progress: 0.8));
        async.flushMicrotasks();
        expect(sink.frames, hasLength(2));
        expect(sink.frames.last.alert, isTrue);
      });
    });

    test('end cancels through the sink', () {
      fakeAsync((async) {
        final sink = _RecordingSink();
        final c = LiveActivities(sink: sink, now: async.getClock(DateTime(2026)).now);
        c.update(_snap());
        c.end('order:1');
        async.flushMicrotasks();
        expect(sink.cancelled, ['order:1']);
        expect(c.isActive('order:1'), isFalse);
      });
    });

    test('inert without a sink, and a throwing sink never escapes', () async {
      final c = LiveActivities();
      await c.update(_snap());
      final bad = LiveActivities(sink: _ThrowingSink());
      await bad.update(_snap());
    });
  });
}

class _ThrowingSink implements LiveActivitySink {
  @override
  Future<void> show(LiveActivityFrame frame) => throw StateError('boom');

  @override
  Future<void> cancel(int id, String key) => throw StateError('boom');
}
