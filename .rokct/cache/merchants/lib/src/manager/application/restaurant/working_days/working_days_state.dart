import 'package:base_sdk/src/models/data/shop_data.dart';

/// Plain immutable state (merchants_sdk convention — see
/// `application/main/main_state.dart`).
class WorkingDaysState {
  const WorkingDaysState({
    this.isLoading = false,
    this.currentIndex = 0,
    this.workingDays = const [],
  });

  final bool isLoading;
  final int currentIndex;
  final List<ShopWorkingDay> workingDays;

  WorkingDaysState copyWith({
    bool? isLoading,
    int? currentIndex,
    List<ShopWorkingDay>? workingDays,
  }) =>
      WorkingDaysState(
        isLoading: isLoading ?? this.isLoading,
        currentIndex: currentIndex ?? this.currentIndex,
        workingDays: workingDays ?? this.workingDays,
      );
}
