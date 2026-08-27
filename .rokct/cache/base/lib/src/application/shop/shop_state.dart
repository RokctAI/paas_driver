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
import 'package:base_sdk/src/models/models.dart';

import 'package:base_sdk/src/models/response/all_products_response.dart';

part 'shop_state.freezed.dart';

@freezed
abstract class ShopState with _$ShopState {
  const factory ShopState({
    @Default(false) bool isLoading,
    @Default(false) bool isFilterLoading,
    @Default(true) bool isCategoryLoading,
    @Default(true) bool isPopularLoading,
    @Default(true) bool isProductLoading,
    @Default(false) bool isProductCategoryLoading,
    @Default(false) bool isPopularProduct,
    @Default(true) bool isBrandsLoading,
    @Default(false) bool isLike,
    @Default(false) bool showWeekTime,
    @Default(false) bool showBranch,
    @Default(false) bool isMapLoading,
    @Default(false) bool isGroupOrder,
    @Default(false) bool isJoinOrder,
    @Default(false) bool isSearchEnabled,
    @Default(false) bool isTodayWorkingDay,
    @Default(false) bool isTomorrowWorkingDay,
    @Default(false) bool isNestedScrollDisabled,
    @Default("") String userUuid,
    @Default("") String searchText,
    @Default(TimeOfDay(hour: 0, minute: 0)) TimeOfDay startTodayTime,
    @Default(TimeOfDay(hour: 0, minute: 0)) TimeOfDay endTodayTime,
    @Default(0) int currentIndex,
    @Default(0) int subCategoryIndex,
    @Default({}) Set<Marker> shopMarkers,
    @Default([]) List<LatLng> polylineCoordinates,
    @Default(null) ShopData? shopData,
    // @Default([]) List<ProductData> products,
    // @Default([]) List<ProductData> popularProducts,
    @Default([]) List<ProductData> categoryProducts,
    @Default([]) List<All> allData,
    @Default([]) List<CategoryData>? category,
    @Default([]) List<BrandData>? brands,
    @Default([]) List<BranchModel>? branches,
    @Default([]) List<String> brandIds,
    @Default(0) int sortIndex,
  }) = _ShopState;

  const ShopState._();
}
