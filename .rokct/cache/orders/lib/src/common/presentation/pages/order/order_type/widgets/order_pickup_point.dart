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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:base_sdk/src/application/delivery_points/delivery_points_provider.dart';
import 'package:base_sdk/src/application/order/order_provider.dart';
import 'package:base_sdk/src/models/data/delivery_point_data.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/location_service.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/loading.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class OrderPickupPoint extends ConsumerStatefulWidget {
  const OrderPickupPoint({super.key});

  @override
  ConsumerState<OrderPickupPoint> createState() => _OrderPickupPointState();
}

class _OrderPickupPointState extends ConsumerState<OrderPickupPoint> {
  final Completer<GoogleMapController> _mapController = Completer();
  final LocationService _locationService = LocationService();
  LatLng? _initialPosition;
  DeliveryPointData? _selectedPoint;

  @override
  void initState() {
    super.initState();
    _fetchLocationAndDeliveryPoints();
  }

  Future<void> _fetchLocationAndDeliveryPoints() async {
    final position = await _locationService.determinePosition(context);
    if (position != null && mounted) {
      setState(() {
        _initialPosition = LatLng(position.latitude, position.longitude);
      });
      ref.read(deliveryPointsProvider.notifier).fetchDeliveryPoints(
            context,
            latitude: position.latitude,
            longitude: position.longitude,
          );
    }
  }

  Set<Marker> _createMarkers(List<DeliveryPointData> points) {
    return points.map((point) {
      return Marker(
        markerId: MarkerId(point.name ?? UniqueKey().toString()),
        position: LatLng(point.latitude ?? 0, point.longitude ?? 0),
        infoWindow: InfoWindow(title: point.name, snippet: point.address),
        onTap: () {
          setState(() {
            _selectedPoint = point;
          });
        },
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deliveryPointsProvider);
    final notifier = ref.read(orderProvider.notifier);

    return state.isLoading || _initialPosition == null
        ? const Loading()
        : Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(
                      target: _initialPosition!,
                      zoom: 14,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      _mapController.complete(controller);
                    },
                    markers: _createMarkers(state.deliveryPoints),
                  ),
                ),
              ),
              if (_selectedPoint != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    tileColor: AppStyle.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    title: Text(
                      _selectedPoint!.name ?? '',
                      style: AppStyle.interSemi(color: AppStyle.white),
                    ),
                    subtitle: Text(
                      _selectedPoint!.address ?? '',
                      style: AppStyle.interRegular(color: AppStyle.white),
                    ),
                  ),
                ),
              CustomButton(
                title: AppHelpers.getTranslation(TrKeys.confirmLocation),
                onPressed: _selectedPoint == null
                    ? null
                    : () {
                        notifier.setDeliveryPoint(_selectedPoint);
                        AppHelpers.showCheckTopSnackBarDone(
                          context,
                          "${AppHelpers.getTranslation(TrKeys.select)}: ${_selectedPoint!.name}",
                        );
                      },
              ),
            ],
          );
  }
}
