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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:base_sdk/src/guide/guide_anchor.dart';
import 'package:base_sdk/src/guide/guide_definition.dart';
import 'package:base_sdk/src/guide/guide_host.dart';
import 'package:base_sdk/src/guide/guide_progress.dart';
import 'package:base_sdk/src/guide/guide_store.dart';
import 'package:base_sdk/src/services/demo_session.dart';
import 'package:base_sdk/src/services/local_storage.dart';

const _guide = GuideDefinition(id: 'test', steps: [
  GuideStep(
      id: 's1', anchor: 't.button', title: 'Start here', body: 'Tap to start.'),
]);

Widget _scene() => MaterialApp(
      home: Scaffold(
        body: Center(
          child: GuideAnchor(
            id: 't.button',
            child: ElevatedButton(onPressed: () {}, child: const Text('Go')),
          ),
        ),
      ),
    );

Widget _host(GuideStore store) => MaterialApp(
      home: GuideHost(
        definition: _guide,
        store: store,
        pollInterval: const Duration(milliseconds: 50),
        child: Scaffold(
          body: Center(
            child: GuideAnchor(
              id: 't.button',
              child: ElevatedButton(onPressed: () {}, child: const Text('Go')),
            ),
          ),
        ),
      ),
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    await DemoSession.instance.clear();
  });

  testWidgets('shows the next step once its anchor is on screen',
      (tester) async {
    final store = InMemoryGuideStore();
    await tester.pumpWidget(_host(store));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Start here'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);
  });

  testWidgets('Got it marks the step complete and removes the coach-mark',
      (tester) async {
    final store = InMemoryGuideStore();
    await tester.pumpWidget(_host(store));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    await tester.runAsync(() async {
      await tester.tap(find.text('Got it'));
    });
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Start here'), findsNothing);
    final saved = await store.read('test');
    expect(saved.completed, {'s1'});
    expect(saved.isFinished(_guide), isTrue);
  });

  testWidgets('a finished guide is not shown again on a later visit',
      (tester) async {
    final store = InMemoryGuideStore()
      ..records['test'] = const GuideProgress.fresh().markComplete('s1');
    await tester.pumpWidget(_host(store));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Start here'), findsNothing);
  });

  testWidgets('demo sessions show nothing and write nothing', (tester) async {
    await DemoSession.instance.activate();
    final store = InMemoryGuideStore();
    await tester.pumpWidget(_host(store));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Start here'), findsNothing);
    expect(store.records, isEmpty);
  });

  testWidgets('no anchor on screen means no coach-mark', (tester) async {
    final store = InMemoryGuideStore();
    await tester.pumpWidget(MaterialApp(
      home: GuideHost(
        definition: _guide,
        store: store,
        pollInterval: const Duration(milliseconds: 50),
        child: const Scaffold(body: Text('no anchor here')),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Start here'), findsNothing);
  });

  test('GuideAnchors.isOnScreen is false for an unknown id', () {
    expect(GuideAnchors.isOnScreen('never.mounted'), isFalse);
  });

  testWidgets('scene without the host renders the anchor normally',
      (tester) async {
    await tester.pumpWidget(_scene());
    expect(find.text('Go'), findsOneWidget);
  });
}
