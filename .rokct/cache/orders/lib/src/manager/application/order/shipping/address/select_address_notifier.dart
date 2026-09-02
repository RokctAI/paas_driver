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

import 'package:flutter/widgets.dart';
import 'package:osm_nominatim/osm_nominatim.dart';
import 'package:location/location.dart' as location;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'select_address_state.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

class SelectAddressNotifier extends StateNotifier<SelectAddressState> {
  Timer? _timer;

  SelectAddressNotifier()
      : super(SelectAddressState(textController: TextEditingController()));

  void setQuery(BuildContext context) {
    if (state.textController?.text.trim().isNotEmpty ?? false) {
      if (_timer?.isActive ?? false) {
        _timer?.cancel();
      }
      _timer = Timer(
        const Duration(milliseconds: 500),
        () {
          searchLocations();
        },
      );
    }
  }

  Future<void> searchLocations() async {
    state = state.copyWith(isSearching: true, isSearchLoading: true);
    try {
      final result = await Nominatim.searchByName(
        query: state.textController?.text.trim() ?? '',
        limit: 5,
        addressDetails: true,
        extraTags: true,
        nameDetails: true,
      );
      state = state.copyWith(searchedPlaces: result, isSearchLoading: false);
    } catch (e) {
      debugPrint('===> search location error $e');
      state = state.copyWith(isSearchLoading: false);
    }
  }

  void clearSearchField() {
    state.textController?.clear();
    state = state.copyWith(searchedPlaces: [], isSearching: false);
  }

  void setMapController(GoogleMapController controller) {
    state = state.copyWith(mapController: controller);
  }

  void setChoosing(bool value) {
    state = state.copyWith(isChoosing: value, isSearching: false);
  }

  void goToLocation({required Place place}) {
    state = state.copyWith(isSearching: false);
    state.textController?.text = place.displayName;
    state.mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          bearing: 0,
          target: LatLng(place.lat, place.lon),
          tilt: 0,
          zoom: 17,
        ),
      ),
    );
    state = state.copyWith(
      location: LocationModel(latitude: place.lat, longitude: place.lon),
    );
  }

  Future<void> goToMyLocation(location.LocationData locationData) async {
    state = state.copyWith(searchedPlaces: [], isSearching: false);
    Place? place;
    try {
      place = await Nominatim.reverseSearch(
        lat: locationData.latitude,
        lon: locationData.longitude,
        addressDetails: true,
        extraTags: true,
        nameDetails: true,
      );
      state.textController?.text = place.displayName;
    } catch (e) {
      debugPrint('===> go to my location error: $e');
      state.textController?.text = '';
    }
    if (place != null) {
      state.mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            bearing: 0,
            target: LatLng(place.lat, place.lon),
            tilt: 0,
            zoom: 17,
          ),
        ),
      );
      state = state.copyWith(
        location: LocationModel(latitude: place.lat, longitude: place.lon),
      );
    }
  }

  Future<void> findMyLocation() async {
    location.LocationData? myLocationData;
    final locationInstance = location.Location();
    bool serviceEnabled;
    location.PermissionStatus permissionGranted;
    serviceEnabled = await locationInstance.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await locationInstance.requestService();
      if (!serviceEnabled) {
        return;
      }
    }
    permissionGranted = await locationInstance.hasPermission();
    if (permissionGranted == location.PermissionStatus.denied) {
      permissionGranted = await locationInstance.requestPermission();
      if (permissionGranted != location.PermissionStatus.granted) {
        return;
      }
    }
    try {
      myLocationData = await locationInstance.getLocation();
    } catch (e) {
      myLocationData = null;
    }
    if (myLocationData != null) {
      goToMyLocation(myLocationData);
    }
  }

  Future<void> saveLocalAddress(
    bool? hasBack, {
    VoidCallback? onBack,
    VoidCallback? onGoMain,
  }) async {
    clearSearchField();
    state.mapController?.dispose();
  }

  Future<void> fetchLocationName(LatLng? latLng) async {
    state = state.copyWith(
      location: LocationModel(
        latitude: latLng?.latitude,
        longitude: latLng?.longitude,
      ),
    );
    Place? place;
    try {
      place = await Nominatim.reverseSearch(
        lat: latLng?.latitude,
        lon: latLng?.longitude,
        addressDetails: true,
        extraTags: true,
        nameDetails: true,
      );
      state.textController?.text = place.displayName;
    } catch (e) {
      state.textController?.text = '';
    }
  }
}
