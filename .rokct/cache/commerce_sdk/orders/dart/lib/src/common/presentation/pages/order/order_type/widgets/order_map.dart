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
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:base_sdk/src/presentation/components/loading.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

class OrderMap extends StatelessWidget {
  final Set<Marker> markers;
  final bool isLoading;
  final LatLng latLng;
  final List<LatLng> polylineCoordinates;

  const OrderMap({
    super.key,
    required this.markers,
    required this.latLng,
    required this.polylineCoordinates,
    required this.isLoading,
  });

  LatLngBounds _bounds(Set<Marker> markers) {
    if (markers.isEmpty) {
      return LatLngBounds(
        southwest: const LatLng(0, 0),
        northeast: const LatLng(0, 0),
      );
    }
    return _createBounds(markers.map((m) => m.position).toList());
  }

  LatLngBounds _createBounds(List<LatLng> positions) {
    final southwestLat = positions.map((p) => p.latitude).reduce(
          (value, element) => value < element ? value : element,
        ); // smallest
    final southwestLon = positions
        .map((p) => p.longitude)
        .reduce((value, element) => value < element ? value : element);
    final northeastLat = positions.map((p) => p.latitude).reduce(
          (value, element) => value > element ? value : element,
        ); // biggest
    final northeastLon = positions
        .map((p) => p.longitude)
        .reduce((value, element) => value > element ? value : element);
    return LatLngBounds(
      southwest: LatLng(southwestLat, southwestLon),
      northeast: LatLng(northeastLat, northeastLon),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppStyle.white,
        borderRadius: BorderRadius.circular(10.r),
      ),
      padding: EdgeInsets.all(16.r),
      height: 260.h,
      child: isLoading
          ? const Center(child: Loading())
          : GoogleMap(
              padding: REdgeInsets.only(bottom: 15),
              myLocationButtonEnabled: false,
              zoomGesturesEnabled: true,
              markers: markers,
              onMapCreated: (GoogleMapController controller) {
                controller.animateCamera(
                  CameraUpdate.newLatLngBounds(_bounds(markers), 50),
                );
              },
              polylines: {
                Polyline(
                  polylineId: const PolylineId("market"),
                  points: polylineCoordinates,
                  color: AppStyle.primary,
                  width: 6,
                ),
              },
              initialCameraPosition: CameraPosition(target: latLng, zoom: 10),
              mapToolbarEnabled: false,
              zoomControlsEnabled: true,
            ),
    );
  }
}
