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

import 'package:flutter_test/flutter_test.dart';

import 'package:base_sdk/src/guide/guide_definition.dart';
import 'package:base_sdk/src/guide/guide_progress.dart';
import 'package:base_sdk/src/guide/guide_store.dart';

const _guide = GuideDefinition(id: 'orders', steps: [
  GuideStep(id: 'a', anchor: 'orders.create', title: 'A', body: 'a'),
  GuideStep(id: 'b', anchor: 'orders.list', title: 'B', body: 'b'),
  GuideStep(id: 'c', anchor: 'orders.filter', title: 'C', body: 'c'),
]);

void main() {
  group('GuideProgress rules', () {
    test('a fresh guide is on with nothing completed, first step next', () {
      const p = GuideProgress.fresh();
      expect(p.enabled, isTrue);
      expect(p.completed, isEmpty);
      expect(p.nextStep(_guide)?.id, 'a');
    });

    test('a completed step is never offered again', () {
      final p = const GuideProgress.fresh().markComplete('a');
      expect(p.nextStep(_guide)?.id, 'b');
      expect(p.markComplete('a'), same(p));
    });

    test('a step whose anchor is off screen is passed over, not completed',
        () {
      const p = GuideProgress.fresh();
      final next = p.nextStep(_guide, isOnScreen: (anchor) => anchor != 'orders.create');
      expect(next?.id, 'b');
      expect(p.completed, isEmpty);
      // Once the anchor appears, the skipped step is shown.
      expect(p.nextStep(_guide, isOnScreen: (_) => true)?.id, 'a');
    });

    test('turning OFF keeps progress and offers nothing', () {
      final p = const GuideProgress.fresh()
          .markComplete('a')
          .setEnabled(false, _guide);
      expect(p.enabled, isFalse);
      expect(p.completed, {'a'});
      expect(p.nextStep(_guide), isNull);
    });

    test('turning back ON an unfinished guide resumes from its progress', () {
      final off = const GuideProgress.fresh()
          .markComplete('a')
          .setEnabled(false, _guide);
      final on = off.setEnabled(true, _guide);
      expect(on.enabled, isTrue);
      expect(on.completed, {'a'});
      expect(on.nextStep(_guide)?.id, 'b');
    });

    test('turning ON a finished guide starts it clean, as if never used', () {
      final finished = const GuideProgress.fresh().dismissAll(_guide);
      expect(finished.isFinished(_guide), isTrue);
      final restarted = finished.setEnabled(true, _guide);
      expect(restarted.completed, isEmpty);
      expect(restarted.enabled, isTrue);
      expect(restarted.nextStep(_guide)?.id, 'a');
    });

    test('finishing the last step marks the guide finished', () {
      final p = const GuideProgress.fresh()
          .markComplete('a')
          .markComplete('b')
          .markComplete('c');
      expect(p.isFinished(_guide), isTrue);
      expect(p.nextStep(_guide), isNull);
    });

    test('skip-all counts every step as seen', () {
      final p = const GuideProgress.fresh().dismissAll(_guide);
      expect(p.completed, {'a', 'b', 'c'});
      expect(p.nextStep(_guide), isNull);
    });
  });

  group('GuideProgress storage shape', () {
    test('round-trips through JSON', () {
      final p = const GuideProgress.fresh()
          .markComplete('a')
          .setEnabled(false, _guide);
      final back = GuideProgress.fromJson(p.toJson());
      expect(back, isNotNull);
      expect(back!.enabled, isFalse);
      expect(back.completed, {'a'});
    });

    test('a corrupt or foreign blob reads as null, never throws', () {
      expect(GuideProgress.fromJson(null), isNull);
      expect(GuideProgress.fromJson('nope'), isNull);
      expect(GuideProgress.fromJson({'version': 2, 'enabled': true}), isNull);
      expect(GuideProgress.fromJson({'version': 1, 'enabled': 'yes'}), isNull);
    });

    test('the in-memory store starts fresh and keeps what it was given',
        () async {
      final store = InMemoryGuideStore();
      expect((await store.read('orders')).completed, isEmpty);
      await store.write('orders', const GuideProgress.fresh().markComplete('a'));
      expect((await store.read('orders')).completed, {'a'});
    });
  });
}
