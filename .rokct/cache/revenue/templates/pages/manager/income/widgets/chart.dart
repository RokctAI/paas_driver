import 'package:auto_size_text/auto_size_text.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:${package}/presentation/styles/style.dart';
import 'package:${package}/presentation/theme/theme.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/presentation/components/loading.dart';
// Chart model plus the findPriceIndex/findPrice/findPriceWithHour lookup
// extensions the spot mapping below uses.
import 'package:revenue_sdk/src/common/infrastructure/models/response/statistics_response.dart';

class SalesChart extends StatelessWidget {
  final List<num> price;
  final List<DateTime> times;
  final List<Chart> chart;
  final bool isDay;
  final bool isLoading;

  const SalesChart({
    super.key,
    required this.price,
    required this.chart,
    required this.times,
    required this.isDay,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 268.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          SizedBox(
            width: times.length > 7
                ? times.length * 40
                : MediaQuery.sizeOf(context).width - 80,
            child: Padding(
              padding: REdgeInsets.only(top: 24),
              child: isLoading
                  ? const Loading()
                  : chart.isNotEmpty
                  ? LineChart(mainData())
                  : Center(
                      child: Text(
                        AppHelpers.getTranslation(TrKeys.needOrder),
                        style: AppStyle.interSemi(size: 22),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    final style = AppStyle.interRegular(size: 10);
    // fl_chart 0.69.x: SideTitleWidget takes `axisSide` (`meta` is its
    // 0.70+ replacement, which the composed manager does not resolve yet).
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Padding(
        padding: REdgeInsets.only(top: 4),
        child: Text(
          DateFormat(isDay ? "HH:00" : "MMM d").format(times[value.ceil()]),
          style: style,
        ),
      ),
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    final style = AppStyle.interRegular(size: 12);
    return AutoSizeText(
      AppHelpers.numberFormat(
        number: value.toInt() == 0 ? 0 : price[value.toInt() - 1],
      ),
      style: style,
      textAlign: TextAlign.left,
      maxLines: 1,
    );
  }

  LineChartData mainData() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 1,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return const FlLine(
            color: AppStyle.iconButtonBack,
            strokeWidth: 1,
            dashArray: [10],
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24.r,
            interval: 1,
            getTitlesWidget: bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: leftTitleWidgets,
            reservedSize: 60.r,
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: times.length.toDouble() - 1,
      minY: 0,
      maxY: 7,
      lineBarsData: [
        LineChartBarData(
          spots: [
            ...times.mapIndexed(
              (e, i) => FlSpot(
                i.toDouble(),
                price.findPriceIndex(
                  isDay ? chart.findPriceWithHour(e) : chart.findPrice(e),
                ),
              ),
            ),
          ],
          isCurved: true,
          color: AppStyle.primary,
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: Style.primaryGradient,
            ),
          ),
        ),
      ],
    );
  }
}

