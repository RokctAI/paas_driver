import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import 'package:merchants_sdk/src/manager/application/restaurant/working_days/working_days_notifier.dart';
import 'package:merchants_sdk/src/manager/application/restaurant/working_days/working_days_state.dart';
import 'package:merchants_sdk/src/manager/domain/interface/seller_shop.dart';

final workingDaysProvider =
    StateNotifierProvider<WorkingDaysNotifier, WorkingDaysState>(
  (ref) => WorkingDaysNotifier(GetIt.instance<SellerShopRepositoryFacade>()),
);
