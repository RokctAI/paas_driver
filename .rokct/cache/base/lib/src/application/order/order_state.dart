// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
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
