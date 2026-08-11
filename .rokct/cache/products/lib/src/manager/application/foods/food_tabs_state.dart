class FoodTabsState {
  const FoodTabsState({this.selectedIndex = 0});

  final int selectedIndex;

  FoodTabsState copyWith({int? selectedIndex}) =>
      FoodTabsState(selectedIndex: selectedIndex ?? this.selectedIndex);
}
