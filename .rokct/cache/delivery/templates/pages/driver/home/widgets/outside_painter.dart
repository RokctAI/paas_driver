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

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class OutsidePolygonPainter extends CustomPainter {
  final List<LatLng> polygonLatLngs;
  OutsidePolygonPainter(this.polygonLatLngs);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.red.withOpacity(0.5) // Color for the outside area
      ..style = PaintingStyle.fill;

    Path path = Path()
      ..addRect(
          Rect.fromLTWH(0, 0, size.width, size.height)); // Cover entire map

    // Convert LatLng to screen coordinates
    for (int i = 0; i < polygonLatLngs.length; i++) {
      if (i == 0) {
        path.moveTo(polygonLatLngs[i].latitude, polygonLatLngs[i].longitude);
      } else {
        path.lineTo(polygonLatLngs[i].latitude, polygonLatLngs[i].longitude);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
