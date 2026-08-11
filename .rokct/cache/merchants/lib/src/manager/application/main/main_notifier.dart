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
