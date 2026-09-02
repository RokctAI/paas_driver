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
import 'package:base_sdk/src/services/local_storage.dart';

import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/application/main/main_state.dart';

class MainNotifier extends StateNotifier<MainState> {
  MainNotifier() : super(const MainState());

  void selectIndex(int index) {
    state = state.copyWith(selectIndex: index);
  }

  // Add this method to reset to the initial page
  void resetToInitialPage() {
    // Assuming index 0 is the home/main page
    state = state.copyWith(selectIndex: 0);
  }

  bool checkGuest() {
    return LocalStorage.getToken().isEmpty;
  }

  void changeScrolling(bool isScrolling) {
    if (!AppConstants.fixed) {
      state = state.copyWith(isScrolling: isScrolling);
    } else {
      state = state.copyWith(isScrolling: false);
    }
  }
}
