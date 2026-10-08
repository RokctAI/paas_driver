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

// Demo runs the REAL courier repositories: base_sdk's DemoGatewayInterceptor
// answers every platform cmd from templates/assets/demo/delivery/<cmd>.json.
// These tests drive the real repositories through the real HttpService Dio
// stack in a demo session, pin that the DI hook registers the real
// repositories whatever the session says, and keep the remaining demo
// seams (pinned GPS, delete-account gate) on DemoSession.demoActive.

import 'dart:io';

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/services/demo_session.dart';
import 'package:delivery_sdk/src/driver/di/driver_delivery_di.dart';
import 'package:delivery_sdk/src/driver/domain/interface/courier.dart';
import 'package:delivery_sdk/src/driver/domain/interface/deposit.dart';
import 'package:delivery_sdk/src/driver/domain/interface/load.dart';
import 'package:delivery_sdk/src/driver/domain/interface/orders.dart';
import 'package:delivery_sdk/src/driver/domain/interface/parcel.dart';
import 'package:delivery_sdk/src/driver/domain/interface/poi.dart';
import 'package:delivery_sdk/src/driver/domain/interface/route.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/courier_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/deposit_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/load_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/orders_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/parcel_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/poi_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/route_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/services/courier_location_fix.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'support/demo_fixtures_harness.dart';

/// A host-owned facade, to prove the hook leaves it alone.
class _HostOrders extends CourierOrdersRepository {}

T _ok<T>(ApiResult<T> result) => switch (result) {
      Success(:final data) => data,
      Failure(:final error) => throw TestFailure('demo call failed: $error'),
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(startDemoFixtures);
  tearDown(stopDemoFixtures);

  group('DriverDeliveryDependencies', () {
    test('registers the real repositories in a demo session', () async {
      final GetIt getIt = GetIt.asNewInstance();
      DriverDeliveryDependencies.register(getIt);
      expect(getIt.get<CourierOrdersRepositoryFacade>(),
          isA<CourierOrdersRepository>());
      expect(getIt.get<CourierParcelRepositoryFacade>(),
          isA<CourierParcelRepository>());
      expect(getIt.get<CourierRepositoryFacade>(), isA<CourierRepository>());
      expect(getIt.get<CourierRouteRepositoryFacade>(),
          isA<CourierRouteRepository>());
      expect(getIt.get<DriverDepositRepositoryFacade>(),
          isA<DriverDepositRepository>());
      expect(getIt.get<DriverLoadRepositoryFacade>(),
          isA<DriverLoadRepository>());
      expect(
          getIt.get<DriverPoiRepositoryFacade>(), isA<DriverPoiRepository>());
      await getIt.reset();
    });

    test('a facade the host registered itself is kept', () async {
      final GetIt getIt = GetIt.asNewInstance();
      final _HostOrders hostOwned = _HostOrders();
      getIt.registerSingleton<CourierOrdersRepositoryFacade>(hostOwned);
      DriverDeliveryDependencies.register(getIt);
      expect(getIt.get<CourierOrdersRepositoryFacade>(), same(hostOwned));
      await getIt.reset();
    });
  });

  group('orders from fixtures', () {
    final CourierOrdersRepository repo = CourierOrdersRepository();

    test('active, current, available, history and detail', () async {
      final active = _ok(await repo.getActiveOrders(1)).data!;
      expect(active.map((o) => o.id), ['900001', '900002']);
      expect(_ok(await repo.getActiveOrders(2)).data, isEmpty);
      final current = _ok(await repo.fetchCurrentOrder()).data!;
      expect(current.single.id, '900001');
      final available = _ok(await repo.getAvailableOrders(1));
      expect(available.map((o) => o.id), ['900101', '900102']);
      final history = _ok(await repo.getHistoryOrders(1));
      expect(history.map((o) => o.id), ['899901', '899902']);
      final detail = _ok(await repo.showOrders('900002'));
      expect(detail.data?.id, '900002');
    });

    test('day report, work status and every write acknowledge', () async {
      final report = _ok(await repo.getDayReport(
          from: DateTime.now(), to: DateTime.now()));
      expect(report.deliveredCount, 2);
      expect(report.earned, 20);
      expect(_ok(await repo.getWorkStatus()).canTakeWork, isTrue);
      expect(await repo.setOrder('900101'), isA<Success<dynamic>>());
      expect(await repo.setCurrentOrder('900001'), isA<Success<dynamic>>());
      expect(await repo.updateOrder('900001', 'on_a_way'),
          isA<Success<dynamic>>());
      expect(await repo.confirmCodCollection('900001', 189.9),
          isA<Success<dynamic>>());
      expect(await repo.convertCodToCredit('900001'), isA<Success<dynamic>>());
      expect(await repo.uploadImage('900001', 'x'), isA<Success<dynamic>>());
      expect(await repo.addReview('900001', rating: 5, comment: 'ok'),
          isA<Success<void>>());
      expect(await repo.cancelOrder('900002', 'n'), isA<Success<void>>());
    });
  });

  group('parcels', () {
    final CourierParcelRepository repo = CourierParcelRepository();

    test('own parcels from the fixture, marketplace from the kept seed',
        () async {
      expect(_ok(await repo.getActiveOrders(1)).map((p) => p.id), ['77001']);
      expect(_ok(await repo.getHistoryOrders(1)).map((p) => p.id), ['76901']);
      expect(_ok(await repo.getAvailableOrders(1)).map((p) => p.id), ['77101']);
      expect(_ok(await repo.showParcel('77001')).id, '77001');
      expect(await repo.setParcel('77101'), isA<Success<dynamic>>());
      expect(await repo.updateParcel('77001', 'on_a_way'),
          isA<Success<dynamic>>());
    });
  });

  group('courier, route, deposit, load and points', () {
    test('courier profile, vehicle and zone', () async {
      final CourierRepository repo = CourierRepository();
      final details = _ok(await repo.getDriverDetails());
      expect(details.data?.typeOfTechnique, 'motorbike');
      expect(details.data?.online, isTrue);
      expect(_ok(await repo.getDeliverymanSettingsRaw())
          ['can_convert_cod_to_credit'], 1);
      expect(_ok(await repo.getDeliveryVehicleTypes()), hasLength(3));
      expect(_ok(await repo.getDeliveryZone()), hasLength(5));
      expect(_ok(await repo.getRequestModel()).data, isEmpty);
      final profile = _ok(await repo.updateGeneralInfo(firstName: 'Dumi'));
      expect(profile.data?.firstname, 'Dumi');
    });

    test('dispatch route and POI route', () async {
      final CourierRouteRepository repo = CourierRouteRepository();
      expect(_ok(await repo.getDriverRoute()), hasLength(4));
      expect(_ok(await repo.getDriverRoute(source: DriverRouteSource.pois)),
          isEmpty);
      final route = _ok(await repo.getMyDispatchRoute());
      expect(route.stops, hasLength(4));
      expect(
          await repo.completeDispatchStop(routeId: 'DR-0001', stopName: 'x'),
          isA<Success<dynamic>>());
    });

    test('deposits, load and points of interest', () async {
      final DriverDepositRepository deposits = DriverDepositRepository();
      expect(_ok(await deposits.getDestination()).accepting, isTrue);
      expect(_ok(await deposits.getWalletBalance()), -1240);
      expect(_ok(await deposits.listMyDeposits()), hasLength(2));
      expect(_ok(await DriverLoadRepository().getMyLoad()), isEmpty);
      final DriverPoiRepository poi = DriverPoiRepository();
      expect(_ok(await poi.types()), isEmpty);
      expect(_ok(await poi.nearby(latitude: 0, longitude: 0)), isEmpty);
      expect(_ok(await poi.lookupOwner(phone: '1')).found, isFalse);
    });

    test('a write the demo cannot perform fails loudly', () async {
      final result =
          await DriverLoadRepository().closeLoad(loadOrder: 'LOAD-1');
      expect(result, isA<Failure<dynamic>>());
    });
  });

  group('CourierLocationFix.pinnedBuild', () {
    test('follows the runtime session per read', () async {
      expect(CourierLocationFix.pinnedBuild, isTrue);
      await DemoSession.instance.clear();
      expect(CourierLocationFix.pinnedBuild, isFalse);
    });
  });

  group('source contract', () {
    Iterable<File> dartFilesUnder(String dir) => Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    test('no isDemo read or Demo* repository remains', () {
      for (final file in [
        ...dartFilesUnder('lib'),
        ...dartFilesUnder('templates'),
      ]) {
        final String src = file.readAsStringSync();
        expect(src.contains('AppConstants.isDemo'), isFalse, reason: file.path);
        expect(RegExp(r'Demo(Courier|Driver)\w*Repository').hasMatch(src),
            isFalse,
            reason: file.path);
      }
    });

    test('the installed profile page gates delete-account on the session',
        () {
      final String src =
          File('templates/pages/driver/profile/profile_page.dart')
              .readAsStringSync();
      expect(src, contains('DemoSession.demoActive ? null : _openDeleteAccount'));
    });
  });
}
