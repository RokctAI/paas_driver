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

// The driver home template's on-duty tracking lane must be stoppable.
//
// `getCurrentLocation()` (templates/pages/driver/home/home_page.dart)
// used to call `getPositionStream().listen(...)` and drop the
// subscription, so nothing could cancel it: every toggle to online stacked
// one more listener, each writing `latLng` and the stored address for the
// life of the isolate, page or no page. The routing poll had the same bug
// one release earlier (1.19.1).
//
// The template carries composer placeholders (`${package}`) and cannot be
// imported here, so — as map_sdk's manifest_wiring_test does for its route
// shell — this reads the installed source and pins the shape of the fix:
// the subscription is held, and both places that end the lane (the duty
// toggle's OFF path and dispose) release it together with the poll.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _template = 'templates/pages/driver/home/home_page.dart';

/// The body of the first method whose signature line contains [signature],
/// up to the method's closing brace at class-member indentation.
String _body(String src, String signature) {
  final start = src.indexOf(signature);
  expect(start, isNot(-1), reason: '$signature not found in $_template');
  final end = src.indexOf('\n  }\n', start);
  expect(end, isNot(-1));
  return src.substring(start, end);
}

void main() {
  final src = File(_template).readAsStringSync();

  test('every position-stream listener is held in _positionSub', () {
    final listens = 'getPositionStream()'.allMatches(src).length;
    expect(listens, greaterThan(0));
    expect(
      '_positionSub = _geolocatorPlatform.getPositionStream()'
          .allMatches(src)
          .length,
      listens,
      reason: 'a dropped subscription can never be cancelled',
    );
    expect(src, contains('StreamSubscription<Position>? _positionSub;'));
  });

  test('starting the lane again cancels the earlier listener first', () {
    final lane = _body(src, 'void getCurrentLocation()');
    final cancel = lane.indexOf('_positionSub?.cancel();');
    final listen = lane.indexOf('_positionSub = _geolocatorPlatform');
    expect(cancel, isNot(-1));
    expect(listen, isNot(-1));
    expect(cancel, lessThan(listen));
  });

  test('_stopTracking releases the poll and the stream together', () {
    final stop = _body(src, 'void _stopTracking()');
    expect(stop, contains('timer?.cancel();'));
    expect(stop, contains('_positionSub?.cancel();'));
    expect(stop, contains('_positionSub = null;'));
  });

  test('leaving the page and going off duty both stop the lane', () {
    expect(_body(src, 'void dispose()'), contains('_stopTracking();'));
    // The duty toggle's OFF arm is the `else` that also cancels the
    // background task.
    final off = src.indexOf('Workmanager().cancelAll();');
    expect(off, isNot(-1));
    final arm = src.substring(src.lastIndexOf('} else {', off), off);
    expect(arm, contains('_stopTracking();'));
    expect(arm, isNot(contains('timer?.cancel();')),
        reason: 'the OFF path must not stop only the poll');
  });

  test('a pinned build starts the poll but never the platform lane', () {
    final lane = _body(src, 'void getCurrentLocation()');
    final poll = lane.indexOf('getSetProgressLocation();');
    final gate = lane.indexOf('if (CourierLocationFix.pinnedBuild) return;');
    final platform = lane.indexOf('_geolocatorPlatform.');
    expect(poll, isNot(-1));
    expect(gate, isNot(-1));
    expect(platform, isNot(-1));
    expect(poll, lessThan(gate));
    expect(gate, lessThan(platform));
  });

  test('a pinned fix is not written back over the stored address', () {
    final acquire = _body(src, 'Future<void> _acquireLocation()');
    expect(
      acquire,
      contains('if (!result.pinned) CourierStorage.saveSelectedLocation('),
    );
  });
}
