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


import 'dart:math' show cos, sqrt, asin;

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double p = 0.017453292519943295; // Math.PI / 180
  final double c1 = cos((lat2 - lat1) * p);
  final double c2 = cos(lat1 * p);
  final double c3 = cos(lat2 * p);
  final double c4 = cos((lon2 - lon1) * p);

  final double a = 0.5 - c1 / 2 + c2 * c3 * (1 - c4) / 2;
  return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
}
