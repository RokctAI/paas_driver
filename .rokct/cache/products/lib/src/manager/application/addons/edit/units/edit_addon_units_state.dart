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
import 'package:products_sdk/src/common/infrastructure/models/data/seller_unit_data.dart';

/// Plain immutable state (no freezed) — same reason as the stage 2 states.
class EditAddonUnitsState {
  const EditAddonUnitsState({
    this.isLoading = false,
    this.units = const [],
    this.activeIndex = 0,
    this.unitController,
    this.foodUnit,
  });

  final bool isLoading;
  final List<SellerUnitData> units;
  final int activeIndex;
  final TextEditingController? unitController;
  final SellerUnitData? foodUnit;

  EditAddonUnitsState copyWith({
    bool? isLoading,
    List<SellerUnitData>? units,
    int? activeIndex,
    TextEditingController? unitController,
    SellerUnitData? foodUnit,
  }) =>
      EditAddonUnitsState(
        isLoading: isLoading ?? this.isLoading,
        units: units ?? this.units,
        activeIndex: activeIndex ?? this.activeIndex,
        unitController: unitController ?? this.unitController,
        foodUnit: foodUnit ?? this.foodUnit,
      );
}
