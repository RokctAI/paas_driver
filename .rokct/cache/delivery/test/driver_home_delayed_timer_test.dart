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

// The driver home template's 36-second camera-idle timer must not read
// `ref` once the page is gone.
//
// `_HomePageState` (templates/pages/driver/home/home_page.dart) holds
// `final _delayed = Delayed(milliseconds: 36000)`, base_sdk's one-shot
// timer helper, and its map's `onCameraIdle` scheduled
// `ref.read(homeProvider.notifier).scrolling(false)` on it. `Delayed`
// exposes no cancel (it lives in base_sdk's `tpying_delay.dart`, outside
// this SDK), so a page popped inside that window still had the callback
// fire, and the tablet tour died on:
//
//   Bad state: Cannot use "ref" after the widget was disposed.
//
// The fix guards every callback handed to `_delayed.run` with
// `if (!mounted) return;` before anything else runs.
//
// Why this reads the source rather than pumping the page: the template
// carries nine composer placeholders (`package:${package}/presentation/
// routes/app_router.dart`, `.../pages/push_order/push_order_screen.dart`,
// `.../component/custom_toggle.dart` and six more) that resolve only in a
// composed host's generated `lib/`, so `home_page.dart` cannot be imported
// from this package's test tree at all, and its `initState` opens
// Workmanager, Firebase Messaging, geolocator and the GoogleMap platform
// view. So, as driver_home_tracking_lifecycle_test does for the same
// file, this reads the installed source and pins the shape of the fix.
// Removing either guard, or adding a third `_delayed.run` without one,
// turns it red.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _template = 'templates/pages/driver/home/home_page.dart';

/// Every `_delayed.run(() {` call site with the first statement of its
/// callback body, in source order.
List<({int offset, String firstStatement})> _delayedCallbacks(String src) {
  final sites = <({int offset, String firstStatement})>[];
  final pattern = RegExp(r'_delayed\.run\(\(\)\s*\{');
  for (final m in pattern.allMatches(src)) {
    final body = src.substring(m.end);
    final end = body.indexOf(';');
    expect(end, isNot(-1), reason: 'callback at ${m.start} has no statement');
    sites.add((offset: m.start, firstStatement: body.substring(0, end + 1)));
  }
  return sites;
}

void main() {
  final src = File(_template).readAsStringSync();

  test('the page schedules work on the 36-second Delayed helper', () {
    expect(src, contains('final _delayed = Delayed(milliseconds: 36000);'));
    expect(_delayedCallbacks(src), isNotEmpty);
  });

  test('every _delayed.run callback bails out first when unmounted', () {
    final sites = _delayedCallbacks(src);
    expect(sites.length, '_delayed.run('.allMatches(src).length,
        reason: 'every call site must hand run() an inline closure');
    for (final site in sites) {
      expect(
        site.firstStatement.trim(),
        'if (!mounted) return;',
        reason: 'the _delayed.run callback at offset ${site.offset} can '
            'fire after dispose; nothing may run before the mounted check',
      );
    }
  });

  test('camera idle never reads ref on a disposed page', () {
    final idle = src.indexOf('onCameraIdle: () {');
    expect(idle, isNot(-1));
    final read = src.indexOf(
      'ref.read(homeProvider.notifier).scrolling(false);',
      idle,
    );
    expect(read, isNot(-1));
    final arm = src.substring(idle, read);
    expect(arm, contains('_delayed.run('));
    expect(arm, contains('if (!mounted) return;'),
        reason: 'the camera-idle callback runs 36 s after the last camera '
            'move, long after a popped page has been disposed');
  });
}
