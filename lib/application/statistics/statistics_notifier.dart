import 'package:charts_flutter/flutter.dart';
import 'package:driver/infrastructure/models/models.dart';
import 'package:driver/presentation/styles/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:revenue_sdk/revenue_sdk.dart'
    show CourierStatisticsRepositoryFacade;
import 'statistics_state.dart';

/// Courier earnings/statistics, consumed through revenue_sdk's
/// [CourierStatisticsRepositoryFacade] — the slice was ported out of this
/// app's UserRepositoryImpl into revenue_sdk (src/driver/) on corporate main.
///
/// The pre-fork notifier also carried fetchStatisticsOrder /
/// fetchStatisticsOrderByDay / fetchStatisticsOrderPage over
/// `getStatisticsOrder`. No page or widget in this app called any of them
/// (verified by grep before removal), so they were dropped here rather than
/// wired through the facade; the facade still declares getStatisticsOrder for
/// when a consumer materialises.
class StatisticsNotifier extends StateNotifier<StatisticsState> {
  final CourierStatisticsRepositoryFacade _courierStatistics;

  StatisticsNotifier(this._courierStatistics) : super(const StatisticsState());

  Future<void> fetchStatistics(
      {required DateTime endTime, required DateTime startTime}) async {
    if (state.countData == null) {
      state = state.copyWith(isLoading: true);
    }
    final response = await _courierStatistics.getStatistics(
        startTime: startTime, endTime: endTime);
    response.when(
      success: (data) {
        if (state.countData == null) {
          state = state.copyWith(countData: data, isLoading: false);
        } else {
          state = state.copyWith(countData: data);
        }
        addListInfo();
      },
      failure: (fail, s) {
        if (state.countData == null) {
          state = state.copyWith(isLoading: false);
        }
        debugPrint('==> error with fetching statistics $fail');
      },
    );
  }

  addListInfo() {
    List<OrdinalSales> day = [];

    state.countData?.data?.chart?.forEach((element) {
      day.add(OrdinalSales(
        day: DateFormat("dd MMM").format(element.time ?? DateTime.now()),
        sales: element.totalPrice?.floor() ?? 0,
      ));
    });
    List<Series<OrdinalSales, String>> newList = [];
    newList.add(
      Series(
        id: "chart",
        data: day,
        domainFn: (OrdinalSales sales, _) => sales.day,
        measureFn: (OrdinalSales sales, _) => sales.sales,
        seriesColor: ColorUtil.fromDartColor(Style.primaryColor),
      ),
    );
    state = state.copyWith(list: newList);
  }
}
