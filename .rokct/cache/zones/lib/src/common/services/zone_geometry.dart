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

import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Pure client-side geometry for delivery-zone polygons.
///
/// Backs the zone panel's derived coverage figure (section 39, chip 739 —
/// "≈ 12.4 km² covered"): the zone state carries only vertices, the server
/// stores no area field, and the panel must not pay a network call for a
/// number the ring already implies. Kept free of Flutter imports so it is
/// trivially unit-testable.

/// Mean Earth radius in meters — the same constant android-maps-utils'
/// `SphericalUtil` uses, so figures here agree with anything computed by
/// the Google Maps utility stack.
const double zoneEarthRadiusMeters = 6371009.0;

/// The area of the closed polygon described by [points], in square meters,
/// on a sphere of radius [zoneEarthRadiusMeters].
///
/// Same spherical-excess algorithm as `SphericalUtil.computeArea` (the
/// polar-triangle decomposition), which is exact on the sphere — not the
/// planar shoelace, which drifts at city scale on high latitudes. The ring
/// is treated as implicitly closed (last vertex connects back to the
/// first), matching how the map draws it. Fewer than three vertices
/// enclose nothing and return 0.
double zoneAreaSquareMeters(List<LatLng> points) {
  if (points.length < 3) return 0;
  double total = 0;
  final LatLng last = points.last;
  double prevTan = math.tan(
    (math.pi / 2 - _radians(last.latitude)) / 2,
  );
  double prevLng = _radians(last.longitude);
  for (final point in points) {
    final double tan = math.tan(
      (math.pi / 2 - _radians(point.latitude)) / 2,
    );
    final double lng = _radians(point.longitude);
    total += _polarTriangleArea(tan, lng, prevTan, prevLng);
    prevTan = tan;
    prevLng = lng;
  }
  return (total * zoneEarthRadiusMeters * zoneEarthRadiusMeters).abs();
}

/// [zoneAreaSquareMeters] in km² — the unit the zone panel prints.
double zoneAreaSquareKm(List<LatLng> points) =>
    zoneAreaSquareMeters(points) / 1e6;

/// Signed area of the polar triangle spanned by two vertices and the pole,
/// in steradians. `tan1`/`tan2` are `tan((π/2 − latitude) / 2)` for each
/// vertex; the sign carries the winding direction and cancels across the
/// ring, which is why callers take `.abs()` once at the end.
double _polarTriangleArea(double tan1, double lng1, double tan2, double lng2) {
  final double deltaLng = lng1 - lng2;
  final double t = tan1 * tan2;
  return 2 * math.atan2(t * math.sin(deltaLng), 1 + t * math.cos(deltaLng));
}

double _radians(double degrees) => degrees * math.pi / 180;
