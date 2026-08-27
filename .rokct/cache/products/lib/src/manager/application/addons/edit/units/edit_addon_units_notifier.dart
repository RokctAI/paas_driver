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
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:products_sdk/src/common/domain/interface/seller_catalog.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_unit_data.dart';
import 'package:products_sdk/src/manager/application/addons/edit/units/edit_addon_units_state.dart';

/// Port of `paas_manager`'s `EditAddonUnitsNotifier` — the units picker on the
/// edit-addon flow, seeded with the addon's current unit. Kept separate from
/// `EditFoodUnitsNotifier` (same shape) because the app kept them separate.
class EditAddonUnitsNotifier extends StateNotifier<EditAddonUnitsState> {
  EditAddonUnitsNotifier(this._repository)
      : super(EditAddonUnitsState(unitController: TextEditingController()));

  final SellerCatalogRepositoryFacade _repository;

  void setAddonUnit(SellerUnitData? unit) {
    state = state.copyWith(foodUnit: unit);
    state.unitController?.text = unit?.translation?.title ?? '';
  }

  Future<void> fetchUnits() async {
    if (state.units.isNotEmpty) {
      final List<SellerUnitData> units = List.from(state.units);
      int? index;
      for (int i = 0; i < units.length; i++) {
        if (state.foodUnit?.id == units[i].id) {
          index = i;
        }
      }
      if (index == null) {
        if (state.foodUnit != null) {
          units.insert(0, state.foodUnit!);
        }
        state =
            state.copyWith(units: units, activeIndex: 0, foodUnit: units[0]);
        state.unitController?.text = units[0].translation?.title ?? '';
      } else {
        state = state.copyWith(
          units: units,
          activeIndex: index,
          foodUnit: units[index],
        );
        state.unitController?.text = units[index].translation?.title ?? '';
      }
      return;
    }
    final List<SellerUnitData> units = [];
    if (state.foodUnit != null) {
      units.insert(0, state.foodUnit!);
    }
    state = state.copyWith(
      isLoading: true,
      units: units,
      activeIndex: 0,
      foodUnit: units.isEmpty ? null : units[0],
    );
    final response = await _repository.getUnits();
    response.when(
      success: (data) {
        final List<SellerUnitData> units = List.from(state.units);
        final List<SellerUnitData> newUnits = data.data ?? [];
        for (final newUnit in newUnits) {
          final bool isNew =
              !state.units.any((oldUnit) => oldUnit.id == newUnit.id);
          if (isNew) {
            units.add(newUnit);
          }
        }
        state = state.copyWith(
          units: units,
          isLoading: false,
          foodUnit: units[state.activeIndex],
        );
        if (units.isNotEmpty) {
          state.unitController?.text =
              units[state.activeIndex].translation?.title ?? '';
        }
      },
      failure: (failure, status) {
        state = state.copyWith(isLoading: false);
        debugPrint('====> fetch units fail $failure');
      },
    );
  }

  void setActiveIndex(int index) {
    if (state.activeIndex == index) {
      return;
    }
    final newUnit = state.units[index];
    state = state.copyWith(activeIndex: index, foodUnit: newUnit);
    state.unitController?.text = newUnit.translation?.title ?? '';
  }
}
