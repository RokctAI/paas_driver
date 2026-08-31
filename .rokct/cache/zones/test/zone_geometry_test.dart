// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:zones_sdk/src/common/services/zone_geometry.dart';

void main() {
  group('zoneAreaSquareMeters', () {
    test('fewer than three vertices enclose nothing', () {
      expect(zoneAreaSquareMeters(const []), 0);
      expect(zoneAreaSquareMeters(const [LatLng(0, 0)]), 0);
      expect(
        zoneAreaSquareMeters(const [LatLng(0, 0), LatLng(0, 1)]),
        0,
      );
    });

    test('degenerate ring of repeated vertices encloses nothing', () {
      expect(
        zoneAreaSquareMeters(
          const [LatLng(1, 1), LatLng(1, 1), LatLng(1, 1), LatLng(1, 1)],
        ),
        closeTo(0, 1e-6),
      );
    });

    test('1-degree square at the equator matches the analytic band area', () {
      // Exact area of the lat/lng band 0..1 deg x 0..1 deg on the sphere:
      // R^2 * deltaLng * (sin lat2 - sin lat1). The polygon's top edge is a
      // geodesic rather than the latitude circle, so allow a 0.1% band.
      const ring = [
        LatLng(0, 0),
        LatLng(0, 1),
        LatLng(1, 1),
        LatLng(1, 0),
      ];
      final double expected = zoneEarthRadiusMeters *
          zoneEarthRadiusMeters *
          (math.pi / 180) *
          math.sin(math.pi / 180);
      expect(
        zoneAreaSquareMeters(ring),
        closeTo(expected, expected * 0.001),
      );
    });

    test('winding direction does not change the magnitude', () {
      const ring = [
        LatLng(-26.10, 28.00),
        LatLng(-26.10, 28.08),
        LatLng(-26.16, 28.08),
        LatLng(-26.16, 28.00),
      ];
      expect(
        zoneAreaSquareMeters(ring),
        closeTo(zoneAreaSquareMeters(ring.reversed.toList()), 1e-3),
      );
    });

    test('a city-scale zone lands in the plausible range', () {
      // Roughly 8 km x 6.7 km around Johannesburg: expect tens of km2,
      // nowhere near hectares or thousands of km2.
      const ring = [
        LatLng(-26.10, 28.00),
        LatLng(-26.10, 28.08),
        LatLng(-26.16, 28.08),
        LatLng(-26.16, 28.00),
      ];
      final double km2 = zoneAreaSquareKm(ring);
      expect(km2, greaterThan(40));
      expect(km2, lessThan(70));
    });
  });

  group('zoneAreaSquareKm', () {
    test('is square meters scaled by 1e6', () {
      const ring = [
        LatLng(0, 0),
        LatLng(0, 0.01),
        LatLng(0.01, 0.01),
        LatLng(0.01, 0),
      ];
      expect(
        zoneAreaSquareKm(ring),
        closeTo(zoneAreaSquareMeters(ring) / 1e6, 1e-9),
      );
      // ~1.113 km sides at the equator -> ~1.24 km2.
      expect(zoneAreaSquareKm(ring), closeTo(1.239, 0.01));
    });
  });
}
