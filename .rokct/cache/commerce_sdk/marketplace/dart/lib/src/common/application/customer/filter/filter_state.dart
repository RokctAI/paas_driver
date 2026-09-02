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
import 'package:base_sdk/src/models/data/filter_model.dart';
import 'package:base_sdk/src/models/data/take_data.dart';

import 'package:base_sdk/src/models/data/shop_data.dart';
part 'filter_state.freezed.dart';

@freezed
abstract class FilterState with _$FilterState {
  const factory FilterState({
    @Default(null) FilterModel? filterModel,
    @Default(false) bool freeDelivery,
    @Default(false) bool deals,
    @Default(true) bool open,
    @Default(0) int shopCount,
    @Default(100) double endPrice,
    @Default(1) double startPrice,
    @Default(false) bool isLoading,
    @Default(false) bool isTagLoading,
    @Default(true) bool isShopLoading,
    @Default(true) bool isAllShopsLoading,
    @Default(RangeValues(1, 100)) RangeValues rangeValues,
    @Default([]) List<ShopData> shops,
    @Default([]) List<TakeModel> tags,
    @Default([]) List<int> prices,
    @Default([]) List<ShopData> allShops,
  }) = _FilterState;

  const FilterState._();
}
