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

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:base_sdk/src/models/data/poi_data.dart';

/// The bundle directory a point's [POIData.pin] names a file inside.
const String kPoiPinDirectory = 'assets/images/poi';

/// The markers the customer map draws for [pois] - one per point, at the
/// point's own position, labelled with its own name.
///
/// A marker carries the name and the position and nothing else. There is no
/// tap-through, no detail sheet, no second line: a shopper looking at the
/// map learns where the place is and what it is called, which is all a
/// stored point of interest is public for.
Future<Set<Marker>> buildPoiMarkers(
  List<POIData> pois, {
  void Function(MarkerId markerId)? onTap,
}) async {
  final markers = await Future.wait(
    pois.map((poi) async {
      final markerId = MarkerId(poi.name);
      return Marker(
        markerId: markerId,
        position: LatLng(poi.latitude, poi.longitude),
        icon: await poiMarkerIcon(poi),
        infoWindow: InfoWindow(title: '${poi.name}✅'),
        onTap: onTap == null ? null : () => onTap(markerId),
      );
    }),
  );
  return markers.toSet();
}

/// The icon for one point: its bundled pin, tinted, when the SDK ships one
/// under [kPoiPinDirectory]; the platform's own map pin when it does not.
///
/// The fallback is the normal path today - no pin image ships with map_sdk
/// or base_sdk (see `CustomerPoiRepository.pinAsset`), and a point whose
/// marker threw on a missing asset would take the whole map's markers down
/// with it, because these are built in one `Future.wait`. A shopper gets a
/// pin either way.
Future<BitmapDescriptor> poiMarkerIcon(POIData poi) async {
  final String basename = poi.pin.trim();
  if (basename.isEmpty) return BitmapDescriptor.defaultMarker;
  try {
    // Load the PNG image
    final ByteData data = await rootBundle.load('$kPoiPinDirectory/$basename');
    final Uint8List bytes = data.buffer.asUint8List();

    // Decode the PNG image
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ui.Image image = fi.image;

    // Create a canvas to draw on
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint();

    // Draw the original image
    canvas.drawImage(image, Offset.zero, paint);

    // Apply color filter
    paint.colorFilter = ColorFilter.mode(
      poi.titleColor.withOpacity(0.5),
      BlendMode.srcATop,
    );

    // Convert to image
    final ui.Image coloredImage =
        await pictureRecorder.endRecording().toImage(image.width, image.height);
    final ByteData? byteData =
        await coloredImage.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List coloredImageData = byteData!.buffer.asUint8List();

    // Create BitmapDescriptor from the colored image
    return BitmapDescriptor.fromBytes(coloredImageData);
  } catch (e) {
    debugPrint('===> poi pin $basename could not be drawn: $e');
    return BitmapDescriptor.defaultMarker;
  }
}
