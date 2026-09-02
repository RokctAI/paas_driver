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
