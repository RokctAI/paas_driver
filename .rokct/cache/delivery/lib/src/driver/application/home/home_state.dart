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

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/order_detail.dart';
import 'package:base_sdk/src/models/data/parcel_order.dart';

part 'home_state.freezed.dart';

@freezed
abstract class HomeState with _$HomeState {
  const factory HomeState({
    @Default(false) bool isLoading,
    @Default(false) bool isGoUser,
    @Default(false) bool isGoRestaurant,
    @Default(false) bool isScrolling,
    @Default([]) List<LatLng> polylineCoordinates,
    @Default([]) List<LatLng> endPolylineCoordinates,
    @Default({}) Set<Marker> markers,
    @Default(null) OrderDetailData? orderDetail,
    @Default(null) ParcelOrder? parcelDetail,
    @Default({}) Set<Polygon> polygon,
    @Default([]) List<LatLng> deliveryZone,
  }) = _HomeState;

  const HomeState._();
}
