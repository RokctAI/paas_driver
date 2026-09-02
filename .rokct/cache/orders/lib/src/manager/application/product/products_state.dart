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

import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

part 'products_state.freezed.dart';

@freezed
abstract class ProductsState with _$ProductsState {
  const factory ProductsState({
    @Default(false) bool isLoading,
    @Default([]) List<TypedExtra> typedExtras,
    @Default([]) List<Stock> initialStocks,
    @Default([]) List<int> selectedIndexes,
    @Default(0) int stockCount,
    ProductData? productData,
    Stock? selectedStock,
  }) = _ProductsState;

  const ProductsState._();
}
