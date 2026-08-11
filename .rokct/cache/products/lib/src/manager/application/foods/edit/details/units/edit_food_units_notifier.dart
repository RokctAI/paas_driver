import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:products_sdk/src/common/domain/interface/seller_catalog.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_unit_data.dart';
import 'package:products_sdk/src/manager/application/foods/edit/details/units/edit_food_units_state.dart';

/// Port of `paas_manager`'s `EditFoodUnitsNotifier` — the units picker on the
/// edit-product flow, seeded with the product's current unit.
class EditFoodUnitsNotifier extends StateNotifier<EditFoodUnitsState> {
  EditFoodUnitsNotifier(this._repository)
      : super(EditFoodUnitsState(unitController: TextEditingController()));

  final SellerCatalogRepositoryFacade _repository;

  void setFoodUnit(SellerUnitData? unit) {
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
