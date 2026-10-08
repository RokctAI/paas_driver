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

// HOW CLOSE IS "AT THIS PLACE" — the one number the sell screen asks a
// driver to confirm past.
//
// A sale is attributed to a point, and the point is what the round learns
// from: "this corner buys" is only true if the sale actually happened
// there. A driver two streets away who taps the wrong row teaches the round
// something false, so past this distance the screen ASKS.
//
// IT ASKS, IT NEVER BLOCKS. A van day has too many honest reasons to be
// further off than a GPS fix likes — an old fix, a yard, a phone in a
// pocket, a customer who walked up the road — and a screen that refuses the
// sale is a screen that loses the money. So the rule is one extra tap and
// the sale goes through either way.

import 'dart:math' as math;

/// The proximity rule for selling at a point of interest.
class PoiProximity {
  const PoiProximity._();

  /// Within this many metres of the point, nothing is asked.
  ///
  /// 50 m is deliberately twice the server's own duplicate radius (25 m,
  /// `DUPLICATE_RADIUS_KM`): that radius says two fixes this close are the
  /// same corner, so a driver inside twice it is standing at the place by
  /// any reading a phone can give. Wider than a forecourt, narrower than
  /// the next corner.
  static const double confirmMetres = 50;

  /// Whether being [metres] from the point needs the driver's confirmation.
  ///
  /// An unknown distance NEVER asks: a phone that would not give a fix is
  /// not evidence that he is somewhere else, and one refused permission
  /// must not turn into a dialog on every sale.
  static bool needsConfirming(double? metres) =>
      metres != null && metres > confirmMetres;
}

/// Metres between two positions, on the same great-circle maths the
/// server's own nearby read and route optimiser measure with
/// (`route_utils.haversine`), so a screen and a server cannot disagree
/// about how far off a point is.
///
/// Written out here rather than taken from a package: the app already
/// carries no geo-maths dependency, and half a dozen lines of trigonometry
/// is not worth one.
double metresBetween(
  double fromLatitude,
  double fromLongitude,
  double toLatitude,
  double toLongitude,
) {
  const double earthRadiusMetres = 6371000;
  final dLat = _radians(toLatitude - fromLatitude);
  final dLon = _radians(toLongitude - fromLongitude);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_radians(fromLatitude)) *
          math.cos(_radians(toLatitude)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return earthRadiusMetres *
      2 *
      math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _radians(double degrees) => degrees * math.pi / 180;
