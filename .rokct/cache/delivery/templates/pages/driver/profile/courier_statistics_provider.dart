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

import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:revenue_sdk/revenue_sdk.dart'
    show CourierStatisticsRepositoryFacade, CourierStatisticsResponse;

import 'package:${package}/presentation/routes/app_router.dart';

/// Host-composition seam between delivery_sdk's courier profile/home pages
/// and revenue_sdk's courier earnings facade.
///
/// paas_driver's legacy `profileSettingsProvider` carried this fetch
/// directly, which would make delivery_sdk import revenue_sdk — feature SDKs
/// import only base_sdk, so the earnings read lives in this installed file
/// instead: host code may reach into any composed sibling SDK (revenue_sdk
/// is part of every driver compose, driver.json), and the profile/home
/// templates read it via their `${package}` import of this file.
class CourierProfileStatisticsState {
  final bool isLoading;
  final CourierStatisticsResponse? statistics;

  const CourierProfileStatisticsState({
    this.isLoading = false,
    this.statistics,
  });

  CourierProfileStatisticsState copyWith({
    bool? isLoading,
    CourierStatisticsResponse? statistics,
  }) =>
      CourierProfileStatisticsState(
        isLoading: isLoading ?? this.isLoading,
        statistics: statistics ?? this.statistics,
      );
}

class CourierProfileStatisticsNotifier
    extends StateNotifier<CourierProfileStatisticsState> {
  final CourierStatisticsRepositoryFacade _courierStatistics;

  CourierProfileStatisticsNotifier(this._courierStatistics)
      : super(const CourierProfileStatisticsState());

  /// Port of the legacy `fetchProfileStatistics` (401 handling included:
  /// a dead session logs out and lands on /login, host route classes are
  /// fine here because this is host code).
  Future<void> fetchProfileStatistics({required BuildContext context}) async {
    state = state.copyWith(isLoading: true);
    final response = await _courierStatistics.getCourierStatistics();
    response.when(
      success: (data) {
        state = state.copyWith(statistics: data, isLoading: false);
      },
      failure: (failure, status) {
        if (status == 401) {
          LocalStorage.logout();
          context.router.popUntilRoot();
          context.replaceRoute(const LoginRoute());
        } else {
          state = state.copyWith(isLoading: false);
          AppHelpers.showCheckTopSnackBar(
            context,
            AppHelpers.getTranslation(failure),
          );
        }
      },
    );
  }
}

final courierProfileStatisticsProvider = StateNotifierProvider<
    CourierProfileStatisticsNotifier, CourierProfileStatisticsState>(
  (ref) => CourierProfileStatisticsNotifier(
    GetIt.instance.get<CourierStatisticsRepositoryFacade>(),
  ),
);
