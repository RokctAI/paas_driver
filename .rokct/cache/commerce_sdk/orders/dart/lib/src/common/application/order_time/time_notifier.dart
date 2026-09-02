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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orders_sdk/src/common/application/order_time/time_state.dart';

class TimeNotifier extends StateNotifier<TimeState> {
  TimeNotifier() : super(const TimeState());

  void reset() {
    state = state.copyWith(
      currentIndexOne: 0,
      currentIndexTwo: 0,
      selectIndex: null,
    );
  }

  void changeOne(int index) {
    state = state.copyWith(currentIndexOne: index);
  }

  void selectIndex(int index) {
    state = state.copyWith(selectIndex: index);
  }

  void changeTwo(int index) {
    state = state.copyWith(currentIndexTwo: index);
  }
}
