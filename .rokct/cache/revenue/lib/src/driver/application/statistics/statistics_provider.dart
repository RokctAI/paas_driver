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
