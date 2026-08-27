// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
