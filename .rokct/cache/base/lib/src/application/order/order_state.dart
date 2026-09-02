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
import 'package:base_sdk/src/models/data/get_calculate_data.dart';
import 'package:base_sdk/src/models/data/order_active_model.dart';
import 'package:base_sdk/src/models/data/order_data.dart';
import 'package:base_sdk/src/models/response/branches_response.dart';
import 'package:base_sdk/src/models/data/delivery_point_data.dart';
import 'package:base_sdk/src/models/data/shop_data.dart';
part 'order_state.freezed.dart';

@freezed
abstract class OrderState with _$OrderState {
  const factory OrderState({
    @Default(false) bool isActive,
    @Default(false) bool isOrder,
    @Default(false) bool isLoading,
    @Default(false) bool isMapLoading,
    @Default(false) bool isButtonLoading,
    @Default(false) bool isTodayWorkingDay,
    @Default(false) bool isTomorrowWorkingDay,
    @Default(false) bool isCheckShopOrder,
    @Default(false) bool isAddLoading,
    @Default(false) bool sendOtherUser,
    @Default(null) String? promoCode,
    @Default(null) String? office,
    @Default(null) String? house,
    @Default(null) String? floor,
    @Default(null) String? note,
    @Default(null) String? username,
    @Default(null) String? phoneNumber,
    @Default(TimeOfDay(hour: 0, minute: 0)) TimeOfDay selectTime,
    @Default(null) DateTime? selectDate,
    @Default(null) DeliveryPointData? selectedDeliveryPoint,
    @Default(0) int tabIndex,
    @Default(-1) int branchIndex,
    @Default(null) OrderActiveModel? orderData,
    @Default(null) ShopData? shopData,
    @Default([]) List<BranchModel>? branches,
    @Default(null) GetCalculateModel? calculateData,
    @Default({}) Map<MarkerId, Marker> markers,
    @Default({}) Set<Marker> shopMarkers,
    @Default([]) List<LatLng> polylineCoordinates,
    @Default([]) List<ProductNote> notes,
    @Default([]) List<String> todayTimes,
    @Default([]) List<List<String>> dailyTimes,
  }) = _OrderState;

  const OrderState._();
}
