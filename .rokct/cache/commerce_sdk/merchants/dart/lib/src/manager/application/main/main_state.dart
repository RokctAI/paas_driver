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

  /// Which bottom-nav tab is showing: 0 POS (billing), 1 orders, 2 foods,
  /// 3 restaurant. The POS port (approved strip section 11) put the till
  /// first — a store owner lands on the scanner; the queue moved to 1
  /// (orders_sdk's tour fragment tracks the shift).
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
