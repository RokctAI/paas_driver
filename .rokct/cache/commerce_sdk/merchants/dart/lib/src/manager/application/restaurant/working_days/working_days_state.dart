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
