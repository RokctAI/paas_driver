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

// The demo seller facade must stay WHOLE.
//
// `DemoSellerStatisticsRepository` shipped without `getProfitReport` after
// the interface grew it, and because a demo class is only reachable through
// the facade at runtime nothing caught it until the composed
// `paas_manager` build died in kernel_snapshot_program with
// "The non-abstract class 'DemoSellerStatisticsRepository' is missing
// implementations for these members". The typed binding below is the guard:
// the file stops compiling — here, in the SDK's own test run — the moment a
// member is added to the facade and not to the demo.

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revenue_sdk/src/common/domain/interface/seller_statistics.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/profit_report_response.dart';
import 'package:revenue_sdk/src/manager/infrastructure/repositories/demo_seller_statistics_repository.dart';

ProfitReport? _reportOf(ApiResult<ProfitReportResponse> result) {
  ProfitReport? report;
  result.when(
    success: (data) => report = data.data,
    failure: (fail, status) => report = null,
  );
  return report;
}

void main() {
  // Typed as the FACADE, not the concrete class: this assignment is what
  // fails to compile if the demo ever falls behind the interface again.
  final SellerStatisticsRepositoryFacade repository =
      DemoSellerStatisticsRepository();

  group('the demo seller facade', () {
    test('answers every member the interface declares', () async {
      final now = DateTime.now();
      expect(
        await repository.getStatistics(startTime: now, endTime: now),
        isNotNull,
      );
      expect(await repository.getStatisticsOrder(), isNotNull);
      expect(await repository.getProfitReport(from: now, to: now), isNotNull);
    });
  });

  group('the demo profit report', () {
    test('serves a coherent week rather than a zeroed shell', () async {
      final to = DateTime(2026, 8, 30);
      final from = to.subtract(const Duration(days: 6));
      final report = _reportOf(
        await repository.getProfitReport(from: from, to: to),
      );

      expect(report, isNotNull);
      expect(report!.totals.revenue, greaterThan(0));
      expect(report.totals.profit, greaterThan(0));
      expect(report.totals.orders, greaterThan(0));
      // One bucket per day of the inclusive window.
      expect(report.series.length, 7);
      expect(report.products, isNotEmpty);
    });

    test('keeps the honest unknown bucket rather than pure-profit zeros',
        () async {
      final to = DateTime(2026, 8, 30);
      final from = to.subtract(const Duration(days: 6));
      final report = _reportOf(
        await repository.getProfitReport(from: from, to: to),
      )!;

      expect(report.unknownBucket.isEmpty, isFalse);
      // Excluded revenue is exactly the uncosted remainder — never counted.
      expect(
        report.totals.costedRevenue + report.unknownBucket.revenueExcluded,
        closeTo(report.totals.revenue, 0.001),
      );
      expect(report.totals.ordersCosted, lessThan(report.totals.orders));
      // Margin is a percentage of COSTED revenue only.
      expect(
        report.totals.profit / report.totals.costedRevenue * 100,
        closeTo(report.totals.marginPct, 0.001),
      );
      // One product row carries no cost snapshot, so the "cost not set"
      // state has something to render.
      expect(report.products.any((p) => p.costMissing), isTrue);
    });

    test('splits the status bar across the window order count', () async {
      final to = DateTime(2026, 8, 30);
      final from = to.subtract(const Duration(days: 6));
      final report = _reportOf(
        await repository.getProfitReport(from: from, to: to),
      )!;

      final counted =
          report.statusCounts.values.fold<int>(0, (sum, v) => sum + v);
      expect(counted, report.totals.orders);
      expect(report.statusCounts['delivered'], greaterThan(0));
      expect(report.statusCounts['cancelled'], greaterThan(0));
    });

    test('answers a shifted previous window with different numbers',
        () async {
      // The dashboard calls the endpoint twice per fetch; identical answers
      // would collapse every vs-previous-period delta pill to nothing.
      final to = DateTime(2026, 8, 30);
      final from = to.subtract(const Duration(days: 6));
      final current = _reportOf(
        await repository.getProfitReport(from: from, to: to),
      )!;
      final previous = _reportOf(
        await repository.getProfitReport(
          from: from.subtract(const Duration(days: 7)),
          to: from.subtract(const Duration(days: 1)),
        ),
      )!;

      expect(previous.totals.revenue, isNot(current.totals.revenue));
    });

    test('answers a single day per hour, the way the endpoint does',
        () async {
      final day = DateTime(2026, 8, 30);
      final report = _reportOf(
        await repository.getProfitReport(from: day, to: day),
      )!;

      expect(report.series, isNotEmpty);
      // Hourly labels, not `yyyy-MM-dd` day buckets.
      expect(report.series.first.date, matches(RegExp(r'^\d{2}:00$')));
      expect(
        report.series.fold<double>(0, (sum, p) => sum + p.revenue),
        closeTo(report.totals.revenue, 0.001),
      );
    });
  });
}
