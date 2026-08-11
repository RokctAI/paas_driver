/// Plain immutable state rather than a `freezed` union.
///
/// Sibling SDKs are split on this — `orders_sdk`/`auth_sdk` commit their
/// generated `*.freezed.dart`, `products_sdk` does not — so a hand-written
/// `copyWith` keeps `merchants_sdk` analyzable without a `build_runner` pass
/// (same call revenue_sdk made for its StatisticsState).
///
/// The legacy state (paas_manager `lib/application/main/main_state.dart`)
/// also carried a `List<Widget> listOfWidget` with no reader anywhere in the
/// app, so it is not carried over.
class MainState {
  const MainState({
    this.selectedIndex = 0,
    this.isScrolling = false,
  });

  /// Which bottom-nav tab is showing: 0 orders, 1 foods, 2 restaurant.
  final int selectedIndex;

  /// Collapses the nav pill while a tab's scroll view is moving.
  final bool isScrolling;

  MainState copyWith({
    int? selectedIndex,
    bool? isScrolling,
  }) =>
      MainState(
        selectedIndex: selectedIndex ?? this.selectedIndex,
        isScrolling: isScrolling ?? this.isScrolling,
      );
}
