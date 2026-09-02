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
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:base_sdk/src/models/models.dart';

part 'parcel_state.freezed.dart';

@freezed
abstract class ParcelState with _$ParcelState {
  const factory ParcelState({
    @Default(false) bool isLoading,
    @Default(false) bool isButtonLoading,
    @Default(false) bool isMapLoading,
    @Default(false) bool error,
    @Default(null) LocationModel? locationFrom,
    @Default(null) LocationModel? locationTo,
    @Default(null) String? addressTo,
    @Default(null) String? addressFrom,
    @Default(null) TimeOfDay? time,
    @Default(null) ParcelCalculateResponse? calculate,
    @Default([]) List<TypeModel?> types,
    @Default(0) int selectType,
    @Default(false) bool expand,
    @Default(false) bool anonymous,
    @Default(false) bool codEnabled,
    @Default(null) ParcelOrder? parcel,
    @Default(null) PaymentData? selectPayment,
    @Default({}) Map<MarkerId, Marker> markers,
    @Default([]) List<LatLng> polylineCoordinates,
  }) = _ParcelState;

  const ParcelState._();
}
