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

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Whether the points of interest in hand still cover what the map would
/// draw around [centre].
///
/// [loadedCentre] is the centre the points in hand were read around, or null
/// before anything has been read - the page's first build, which always
/// reads. After that a read happens only once the centre has travelled
/// further than [radiusMeters], the radius the page draws within: the read
/// covers twice that radius, so everything drawable inside the new disc is
/// already in hand until the centre leaves the old one. Camera moves arrive
/// a few metres apart, so this is what keeps a pan from becoming a call per
/// frame.
bool poiReadNeeded({
  required LatLng? loadedCentre,
  required LatLng centre,
  required double radiusMeters,
}) {
  if (loadedCentre == null) return true;
  final double travelled = GeolocatorPlatform.instance.distanceBetween(
    loadedCentre.latitude,
    loadedCentre.longitude,
    centre.latitude,
    centre.longitude,
  );
  return travelled > radiusMeters;
}
