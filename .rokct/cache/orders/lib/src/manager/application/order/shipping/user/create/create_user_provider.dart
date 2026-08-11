import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orders_sdk/src/manager/domain/interface/pos_customers.dart';
import 'create_user_notifier.dart';
import 'create_user_state.dart';

final createUserProvider =
    StateNotifierProvider.autoDispose<CreateUserNotifier, CreateUserState>(
  (ref) => CreateUserNotifier(resolvePosCustomersFacade()),
);
