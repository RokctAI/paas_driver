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


// Demo runs the REAL statistics repositories: both role hooks register the
// real facades, and base_sdk's DemoGatewayInterceptor answers their
// platform cmds from templates/assets/demo/revenue in a demo session.

import 'package:base_sdk/base_sdk.dart' show DemoFixtures;
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:revenue_sdk/src/common/di/revenue_di.dart';
import 'package:revenue_sdk/src/common/domain/interface/courier_statistics.dart';
import 'package:revenue_sdk/src/common/domain/interface/seller_statistics.dart';
import 'package:revenue_sdk/src/driver/di/driver_revenue_di.dart';
import 'package:revenue_sdk/src/driver/infrastructure/repositories/courier_statistics_repository.dart';
import 'package:revenue_sdk/src/manager/di/manager_revenue_di.dart';
import 'package:revenue_sdk/src/manager/infrastructure/repositories/seller_statistics_repository.dart';

import 'support/demo_fixtures_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(startRevenueDemoSession);
  tearDown(endRevenueDemoSession);

  test('role hooks register the real facades and the fixture directory',
      () async {
    final getIt = GetIt.asNewInstance();
    DemoFixtures.reset();
    DriverRevenueDependencies.register(getIt);
    ManagerRevenueDependencies.register(getIt);
    expect(getIt<CourierStatisticsRepositoryFacade>(),
        isA<CourierStatisticsRepository>());
    expect(getIt<SellerStatisticsRepositoryFacade>(),
        isA<SellerStatisticsRepository>());
    expect(DemoFixtures.directories, [revenueDemoFixtureDirectory]);
  });

  test('courier earnings parse from fixtures', () async {
    final repo = CourierStatisticsRepository();
    final counts = await repo.getCourierStatistics();
    counts.when(
      success: (r) => expect(r.data!.deliveredOrdersCount, 128),
      failure: (e, _) => fail('$e'),
    );
    final now = DateTime.now();
    final income = await repo.getStatistics(
        startTime: now.subtract(const Duration(days: 7)), endTime: now);
    income.when(
      success: (r) {
        expect(r.data!.chart, hasLength(7));
        expect(r.data!.totalPrice, 3410);
      },
      failure: (e, _) => fail('$e'),
    );
    (await repo.getStatisticsOrder(page: 1)).when(
      success: (r) => expect(r.data, hasLength(3)),
      failure: (e, _) => fail('$e'),
    );
    (await repo.getStatisticsOrder(page: 2)).when(
      success: (r) => expect(r.data, isEmpty),
      failure: (e, _) => fail('$e'),
    );
  });

  test('store revenue and the profit dashboard parse from fixtures',
      () async {
    final repo = SellerStatisticsRepository();
    final now = DateTime.now();
    (await repo.getStatistics(
            startTime: now.subtract(const Duration(days: 7)), endTime: now))
        .when(
      success: (r) => expect(r.data!.totalCount, 342),
      failure: (e, _) => fail('$e'),
    );
    (await repo.getStatisticsOrder(page: 1)).when(
      success: (r) => expect(r.data, hasLength(3)),
      failure: (e, _) => fail('$e'),
    );
    (await repo.getStatisticsOrder(page: 2)).when(
      success: (r) => expect(r.data, isEmpty),
      failure: (e, _) => fail('$e'),
    );
    (await repo.getProfitReport(
            from: now.subtract(const Duration(days: 6)), to: now))
        .when(
      success: (r) {
        final report = r.data!;
        expect(report.series, hasLength(7));
        expect(report.products.last.costMissing, isTrue);
        expect(report.unknownBucket.orders, greaterThan(0));
        expect(report.totals.marginPct, greaterThan(0));
      },
      failure: (e, _) => fail('$e'),
    );
  });
}
