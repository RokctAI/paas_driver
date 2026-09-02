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

import 'home_appbar_state.dart';

class HomeAppbarNotifier extends StateNotifier<HomeAppbarState> {
  HomeAppbarNotifier() : super(const HomeAppbarState());

  void setAppbarDetails(String title, int count, {int? index}) {
    if (index != null) {
      state = state.copyWith(title: title, totalCount: count, index: index);
    } else {
      state = state.copyWith(title: title, totalCount: count);
    }
  }
}
