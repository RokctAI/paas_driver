import 'package:flutter/material.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:products_sdk/src/common/domain/interface/seller_catalog.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_unit_data.dart';
import 'package:products_sdk/src/manager/application/addons/create/units/create_addon_units_state.dart';

/// Port of `paas_manager`'s `CreateAddonUnitsNotifier` — the units picker on
/// the create-addon flow. Kept separate from `CreateFoodUnitsNotifier` (same
/// shape) because the app kept them separate and the two modals evolve
/// independently.
class CreateAddonUnitsNotifier extends StateNotifier<CreateAddonUnitsState> {
  CreateAddonUnitsNotifier(this._repository)
      : super(CreateAddonUnitsState(unitController: TextEditingController()));

  final SellerCatalogRepositoryFacade _repository;

  Future<void> fetchUnits() async {
    if (state.units.isNotEmpty) {
      return;
    }
    state = state.copyWith(isLoading: true);
    final response = await _repository.getUnits();
    response.when(
      success: (data) {
        final List<SellerUnitData> units = data.data ?? [];
        state = state.copyWith(units: units, isLoading: false);
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
    state = state.copyWith(activeIndex: index);
    state.unitController?.text = state.units[index].translation?.title ?? '';
  }
}
