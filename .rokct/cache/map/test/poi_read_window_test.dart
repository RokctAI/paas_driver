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

// When the map page reads points of interest again.
//
// The page reads once for the centre it opens on and then only when the
// camera has carried the centre clear of the disc the points in hand cover.
// Camera moves arrive a few metres apart, so a decision that leaned the other
// way would turn one pan into a call per frame.

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_sdk/src/common/presentation/pages/view_map/poi_read_window.dart';

/// A metre of latitude either side of the same meridian, so the distances
/// below are the plain north-south ones.
const double _metresPerDegreeLatitude = 111319.49;

LatLng _northOf(LatLng origin, double metres) => LatLng(
      origin.latitude + metres / _metresPerDegreeLatitude,
      origin.longitude,
    );

void main() {
  const LatLng centre = LatLng(-26.204103, 28.047305);
  const double radius = 1000;

  group('poiReadNeeded', () {
    test('reads when nothing has been read yet', () {
      expect(
        poiReadNeeded(
          loadedCentre: null,
          centre: centre,
          radiusMeters: radius,
        ),
        isTrue,
      );
    });

    test('does not read again for the same centre', () {
      expect(
        poiReadNeeded(
          loadedCentre: centre,
          centre: centre,
          radiusMeters: radius,
        ),
        isFalse,
      );
    });

    test('a pan inside the radius costs no read', () {
      for (final metres in const <double>[1, 100, 500, 900]) {
        expect(
          poiReadNeeded(
            loadedCentre: centre,
            centre: _northOf(centre, metres),
            radiusMeters: radius,
          ),
          isFalse,
          reason: '$metres m should have been covered already',
        );
      }
    });

    test('a centre carried beyond the radius reads again', () {
      for (final metres in const <double>[1100, 2500, 40000]) {
        expect(
          poiReadNeeded(
            loadedCentre: centre,
            centre: _northOf(centre, metres),
            radiusMeters: radius,
          ),
          isTrue,
          reason: '$metres m should have needed a read',
        );
      }
    });

    test('the direction travelled does not matter', () {
      expect(
        poiReadNeeded(
          loadedCentre: centre,
          centre: _northOf(centre, -1500),
          radiusMeters: radius,
        ),
        isTrue,
      );
    });
  });
}
