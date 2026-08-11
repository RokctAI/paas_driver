import 'package:flutter/material.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_unit_data.dart';

/// Plain immutable state (no freezed) — same reason as the stage 2 states.
class CreateFoodUnitsState {
  const CreateFoodUnitsState({
    this.isLoading = false,
    this.units = const [],
    this.activeIndex = 0,
    this.unitController,
    this.error,
  });

  final bool isLoading;
  final List<SellerUnitData> units;
  final int activeIndex;
  final TextEditingController? unitController;

  /// Set on a failed fetch; the page decides how to show it.
  final String? error;

  CreateFoodUnitsState copyWith({
    bool? isLoading,
    List<SellerUnitData>? units,
    int? activeIndex,
    TextEditingController? unitController,
    String? error,
  }) =>
      CreateFoodUnitsState(
        isLoading: isLoading ?? this.isLoading,
        units: units ?? this.units,
        activeIndex: activeIndex ?? this.activeIndex,
        unitController: unitController ?? this.unitController,
        error: error,
      );
}
