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

import 'package:products_sdk/src/common/infrastructure/models/data/seller_product_data.dart';

/// Plain immutable state, not `freezed`.
///
/// products_sdk gitignores `*.freezed.dart` and never commits it, so every
/// freezed-backed file in this package fails analysis on a fresh checkout until
/// a `build_runner` pass runs. Hand-written `copyWith` keeps the manager slice
/// analyzable on its own.
class FoodsState {
  const FoodsState({this.isLoading = false, this.foods = const []});

  final bool isLoading;
  final List<SellerProductData> foods;

  FoodsState copyWith({bool? isLoading, List<SellerProductData>? foods}) =>
      FoodsState(
        isLoading: isLoading ?? this.isLoading,
        foods: foods ?? this.foods,
      );
}
