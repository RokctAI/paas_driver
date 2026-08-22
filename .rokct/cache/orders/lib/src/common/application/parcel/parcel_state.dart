// Copyright (c) 2026 RokctAI
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
