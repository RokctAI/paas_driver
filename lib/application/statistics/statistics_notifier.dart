import 'package:charts_flutter/flutter.dart';
import 'package:driver/infrastructure/models/models.dart';
import 'package:driver/presentation/styles/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'statistics_state.dart';
import 'package:driver/domain/interface/interfaces.dart';

class StatisticsNotifier extends StateNotifier<StatisticsState> {
  final UserRepository _userRepository;
  int page = 1;

  StatisticsNotifier(this._userRepository) : super(const StatisticsState());

  Future<void> fetchStatistics({
    required DateTime endTime,
    required DateTime startTime,
  }) async {
    if (state.countData == null) {
      state = state.copyWith(isLoading: true);
    }
    final response = await _userRepository.getStatistics(
      startTime: startTime,
      endTime: endTime,
    );
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

  Future<void> fetchStatisticsOrder({
    DateTime? endTime,
    DateTime? startTime,
  }) async {
    page = 1;
    state = state.copyWith(isLoading: true, isRefresh: true);
    final response = await _userRepository.getStatisticsOrder(
      startTime: startTime,
      endTime: endTime,
      page: 1,
    );
    response.when(
      success: (data) {
        state = state.copyWith(listOfOrder: data.data ?? [], isLoading: false);
      },
      failure: (fail, s) {
        state = state.copyWith(isLoading: false);

        debugPrint('==> error with fetching statistics $fail');
      },
    );
  }

  Future<void> fetchStatisticsOrderByDay({
    DateTime? endTime,
    DateTime? startTime,
  }) async {
    page = 1;
    state = state.copyWith(isLoading: true, isRefresh: false);
    final response = await _userRepository.getStatisticsOrder(
      startTime: startTime,
      endTime: endTime,
      page: 1,
      perPage: 100,
    );
    response.when(
      success: (data) {
        state = state.copyWith(listOfOrder: data.data ?? [], isLoading: false);
      },
      failure: (fail, s) {
        state = state.copyWith(isLoading: false);

        debugPrint('==> error with fetching statistics $fail');
      },
    );
  }

  Future<void> fetchStatisticsOrderPage({
    DateTime? endTime,
    DateTime? startTime,
    RefreshController? refreshController,
  }) async {
    final response = await _userRepository.getStatisticsOrder(
      startTime: startTime,
      endTime: endTime,
      page: ++page,
    );
    response.when(
      success: (data) {
        List<StatisticsOrder> newList = List.from(state.listOfOrder);
        newList.addAll(data.data ?? []);
        refreshController?.loadComplete();
        state = state.copyWith(listOfOrder: newList);
      },
      failure: (fail, s) {
        refreshController?.loadNoData();
        if (state.countData == null) {
          state = state.copyWith(isLoading: false);
        }
        debugPrint('==> error with fetching statistics $fail');
      },
    );
  }

  void addListInfo() {
    List<OrdinalSales> day = [];

    state.countData?.data?.chart?.forEach((element) {
      day.add(
        OrdinalSales(
          day: DateFormat("dd MMM").format(element.time ?? DateTime.now()),
          sales: element.totalPrice?.floor() ?? 0,
        ),
      );
    });
    List<Series<OrdinalSales, String>> newList = [];
    newList.add(
      Series(
        id: "chart",
        data: day,
        domainFn: (OrdinalSales sales, _) => sales.day,
        measureFn: (OrdinalSales sales, _) => sales.sales,
        seriesColor: ColorUtil.fromDartColor(Style.primary),
      ),
    );
    state = state.copyWith(list: newList);
  }
}
