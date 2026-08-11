import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:products_sdk/src/common/domain/interface/seller_catalog.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_unit_data.dart';
import 'package:products_sdk/src/manager/application/foods/create/details/units/create_food_units_state.dart';

/// Port of `paas_manager`'s `CreateFoodUnitsNotifier` — the units picker on
/// the create-product flow. Fetch failures surface as `state.error` instead of
/// an in-notifier snackbar (stage 2 convention).
class CreateFoodUnitsNotifier extends StateNotifier<CreateFoodUnitsState> {
  CreateFoodUnitsNotifier(this._repository)
      : super(CreateFoodUnitsState(unitController: TextEditingController()));

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
        state = state.copyWith(isLoading: false, error: failure);
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
