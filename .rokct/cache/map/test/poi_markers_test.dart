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

// The markers the customer map draws once points arrive.
//
// No pin image ships under assets/images/poi/ - not with map_sdk, not with
// base_sdk - so every point built by CustomerPoiRepository carries an empty
// pin basename and the icon falls back to the platform's own map pin. That
// fallback is the whole reason markers appear at all today, and it is the
// first thing a future pin drop would break, so it is pinned here along with
// one marker per point at the point's own position.

import 'package:base_sdk/src/models/data/poi_data.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_sdk/src/common/infrastructure/repositories/customer_poi_repository.dart';
import 'package:map_sdk/src/common/presentation/pages/view_map/poi_markers.dart';

POIData _poi(String name, double latitude, double longitude, {String pin = ''}) =>
    POIData(
      name: name,
      latitude: latitude,
      longitude: longitude,
      titleColor: Colors.transparent,
      pin: pin,
    );

void main() {
  // rootBundle is reached on the pin path, so the test binding must be up.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('buildPoiMarkers', () {
    test('draws one marker per point, at the point own position', () async {
      final markers = await buildPoiMarkers([
        _poi('Water Point', -26.204103, 28.047305),
        _poi('Clinic', -26.195, 28.056),
      ]);

      expect(markers, hasLength(2));
      final byId = {for (final marker in markers) marker.markerId.value: marker};
      expect(byId.keys, containsAll(<String>['Water Point', 'Clinic']));
      expect(
        byId['Water Point']!.position,
        const LatLng(-26.204103, 28.047305),
      );
      expect(byId['Clinic']!.position, const LatLng(-26.195, 28.056));
    });

    test('labels a marker with the point name and nothing else', () async {
      final markers = await buildPoiMarkers([
        _poi('North Gate · Boom gate', -26.2, 28.05),
      ]);

      final marker = markers.single;
      expect(marker.infoWindow.title, contains('North Gate · Boom gate'));
      expect(marker.infoWindow.snippet, isNull);
    });

    test('a tap is reported as the marker that was tapped', () async {
      final tapped = <String>[];
      final markers = await buildPoiMarkers(
        [_poi('Water Point', -26.2, 28.05)],
        onTap: (markerId) => tapped.add(markerId.value),
      );

      markers.single.onTap!();

      expect(tapped, ['Water Point']);
    });

    test('no points is no markers', () async {
      expect(await buildPoiMarkers(const []), isEmpty);
    });
  });

  group('poiMarkerIcon', () {
    test('falls back to the platform pin when no pin basename is named',
        () async {
      final icon = await poiMarkerIcon(_poi('Water Point', -26.2, 28.05));

      expect(icon, BitmapDescriptor.defaultMarker);
    });

    test('every mapped point takes that fallback today', () async {
      expect(CustomerPoiRepository.pinAsset, isEmpty);

      final icon = await poiMarkerIcon(
        _poi('Water Point', -26.2, 28.05,
            pin: CustomerPoiRepository.pinAsset),
      );

      expect(icon, BitmapDescriptor.defaultMarker);
    });

    test('a named pin that is not in the bundle still yields a marker',
        () async {
      final icon = await poiMarkerIcon(
        _poi('Water Point', -26.2, 28.05, pin: 'not-in-the-bundle.png'),
      );

      expect(icon, BitmapDescriptor.defaultMarker);
    });

    test('the pin directory is the one the bundle would carry', () {
      expect(kPoiPinDirectory, 'assets/images/poi');
    });
  });
}
