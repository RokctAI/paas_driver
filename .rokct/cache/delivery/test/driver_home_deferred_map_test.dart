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

// The driver home template must not mount its GoogleMap until the page
// has settled.
//
// `_HomePageState._mapSurface` (templates/pages/driver/home/
// home_page.dart) builds the page's one `GoogleMap`. Built directly, the
// plugin creates its native view on the page's first frame and fires its
// own un-awaited channel calls once the view connects; a page replaced
// before then (the tour's demo sign-in / sign-out / driver sign-in churn,
// paas_driver run 34049256577, phone leg 4/17 on both attempts) died on
//
//   PlatformException(channel-error, Unable to establish connection on
//   channel: "dev.flutter.pigeon.google_maps_flutter_android.MapsApi
//   .updateTileOverlays.0")
//
// thrown from inside the plugin, where no guard in this file can reach.
// The fix wraps the GoogleMap in `DeferredMapSurface` (this SDK's lib/),
// whose behaviour deferred_map_surface_test.dart pins.
//
// Why this reads the source rather than pumping the page: the template
// carries nine composer placeholders (`package:${package}/...`) that
// resolve only in a composed host's generated `lib/`, so `home_page.dart`
// cannot be imported from this package's test tree, and its `initState`
// opens Workmanager, Firebase Messaging, geolocator and the GoogleMap
// platform view. So, as driver_home_delayed_timer_test does for the same
// file, this reads the installed source and pins the shape of the fix:
// one GoogleMap, and it is the child of a DeferredMapSurface.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _template = 'templates/pages/driver/home/home_page.dart';
const String _import =
    "import 'package:delivery_sdk/src/driver/presentation/widgets/"
    "deferred_map_surface.dart';";

void main() {
  final src = File(_template).readAsStringSync();

  test('the template imports DeferredMapSurface from this SDK', () {
    expect(src, contains(_import));
  });

  test('the page builds exactly one GoogleMap', () {
    expect('GoogleMap('.allMatches(src).length, 1);
  });

  test('the GoogleMap is the child of a DeferredMapSurface', () {
    final map = src.indexOf('GoogleMap(');
    expect(map, isNot(-1));
    final deferred = src.lastIndexOf('DeferredMapSurface(', map);
    expect(deferred, isNot(-1),
        reason: 'the GoogleMap must sit inside a DeferredMapSurface');
    final between = src.substring(deferred, map);
    expect(between, contains('child:'),
        reason: 'the GoogleMap is handed to DeferredMapSurface as child');
    expect(between, isNot(contains(';')),
        reason: 'no statement may separate the two - the map is the '
            'deferred child, not a sibling');
    expect(between, isNot(contains('settleDelay')),
        reason: 'the template keeps the default 800 ms settle delay');
  });

  test('the deferred map keeps the 1.20.1 guards around it', () {
    // The camera moves only on a mounted page (1.19.1 / 1.20.1).
    expect(
        src,
        contains('Future<void> _moveCamera(LatLng target) async {\n'
            '    if (!mounted) return;'));
    // dispose still drops the controller and stops tracking.
    final dispose = src.indexOf('void dispose() {');
    expect(dispose, isNot(-1));
    final body = src.substring(dispose, src.indexOf('super.dispose();'));
    expect(body, contains('_stopTracking();'));
    expect(body, contains('googleMapController = null;'));
  });
}
