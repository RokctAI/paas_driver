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
import 'package:merchants_sdk/src/manager/application/main/main_state.dart';

/// Shell state for the manager home page (bottom-nav tab selection and
/// scroll-collapse). Ported from paas_manager `lib/application/main/
/// main_notifier.dart`; LocalStorage now comes from base_sdk instead of the
/// app's own infrastructure/services barrel.
class MainNotifier extends StateNotifier<MainState> {
  MainNotifier() : super(const MainState());

  void selectIndex(int index) {
    state = state.copyWith(selectedIndex: index);
  }

  void changeScrolling(bool isScrolling) {
    state = state.copyWith(isScrolling: isScrolling);
  }

  bool checkGuest() {
    return LocalStorage.getToken().isEmpty;
  }
}
