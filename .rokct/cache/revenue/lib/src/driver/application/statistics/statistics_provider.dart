import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:revenue_sdk/src/common/domain/interface/courier_statistics.dart';
import 'package:revenue_sdk/src/driver/application/statistics/statistics_notifier.dart';
import 'package:revenue_sdk/src/driver/application/statistics/statistics_state.dart';

/// Same resolution path as the manager slice's provider:
/// [CourierStatisticsRepositoryFacade] is registered against `GetIt.instance`
/// by `DriverRevenueDependencies.register(getIt)`, which driver hosts call
/// from their DI setup (paas_driver's `dependency_manager.dart` passes
/// `GetIt.instance`).
final statisticsProvider =
    StateNotifierProvider<StatisticsNotifier, StatisticsState>(
  (ref) => StatisticsNotifier(
    GetIt.instance<CourierStatisticsRepositoryFacade>(),
  ),
);
