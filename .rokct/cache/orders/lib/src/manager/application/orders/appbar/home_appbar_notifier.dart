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
