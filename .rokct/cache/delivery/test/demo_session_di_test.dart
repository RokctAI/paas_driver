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

// Demo login phase 2: the driver DI hook and every demo gate in this SDK
// follow DemoSession.demoActive (base_sdk 1.61.0) - the compile-time
// IS_DEMO build OR the runtime session a server-marked account opens -
// and the hook re-registers its facades when the session flips.
//
// What a later edit could quietly undo, and what each group pins:
//
//   * with the session off, register() wires the real repositories;
//   * activate() swaps every facade this hook owns for its Demo* twin,
//     and clear() puts the real ones back - the same container, no
//     second register() call;
//   * a facade a host registered itself is never replaced by the flip;
//   * a second register() on the same container neither re-registers nor
//     adds a second listener, and a boot that restores an active session
//     registers the demo twins directly;
//   * the pinned-GPS gate reads the session per call;
//   * no AppConstants.isDemo read remains in lib/ or templates/.

import 'dart:io';

import 'package:base_sdk/src/services/demo_session.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:delivery_sdk/src/driver/di/driver_delivery_di.dart';
import 'package:delivery_sdk/src/driver/domain/interface/courier.dart';
import 'package:delivery_sdk/src/driver/domain/interface/deposit.dart';
import 'package:delivery_sdk/src/driver/domain/interface/orders.dart';
import 'package:delivery_sdk/src/driver/domain/interface/parcel.dart';
import 'package:delivery_sdk/src/driver/domain/interface/route.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/courier_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/demo_courier_orders_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/demo_courier_parcel_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/demo_courier_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/demo_courier_route_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/demo_deposit_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/deposit_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/orders_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/parcel_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/route_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/services/courier_location_fix.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A host-owned facade, to prove the flip leaves it alone.
class _HostOrders extends DemoCourierOrdersRepository {}

void _expectReal(GetIt getIt) {
  expect(getIt.get<CourierOrdersRepositoryFacade>(),
      isA<CourierOrdersRepository>());
  expect(getIt.get<CourierParcelRepositoryFacade>(),
      isA<CourierParcelRepository>());
  expect(getIt.get<CourierRepositoryFacade>(), isA<CourierRepository>());
  expect(getIt.get<CourierRouteRepositoryFacade>(),
      isA<CourierRouteRepository>());
  expect(getIt.get<DriverDepositRepositoryFacade>(),
      isA<DriverDepositRepository>());
}

void _expectDemo(GetIt getIt) {
  expect(getIt.get<CourierOrdersRepositoryFacade>(),
      isA<DemoCourierOrdersRepository>());
  expect(getIt.get<CourierParcelRepositoryFacade>(),
      isA<DemoCourierParcelRepository>());
  expect(getIt.get<CourierRepositoryFacade>(), isA<DemoCourierRepository>());
  expect(getIt.get<CourierRouteRepositoryFacade>(),
      isA<DemoCourierRouteRepository>());
  expect(getIt.get<DriverDepositRepositoryFacade>(),
      isA<DemoDriverDepositRepository>());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GetIt getIt;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocalStorage.init();
    DemoSession.isDemoOverride = false;
    getIt = GetIt.asNewInstance();
  });

  tearDown(() async {
    await DemoSession.instance.clear();
    DriverDeliveryDependencies.detachDemoListener();
    // The override is app-global; never let one test leak into the next.
    DemoSession.isDemoOverride = null;
    await getIt.reset();
  });

  group('DriverDeliveryDependencies', () {
    test('with the session off, register wires the real repositories', () {
      DriverDeliveryDependencies.register(getIt);
      _expectReal(getIt);
    });

    test('activate swaps every owned facade for its demo twin, clear swaps back',
        () async {
      DriverDeliveryDependencies.register(getIt);
      _expectReal(getIt);

      await DemoSession.instance.activate();
      _expectDemo(getIt);

      await DemoSession.instance.clear();
      _expectReal(getIt);
    });

    test('a facade the host registered itself survives the flip', () async {
      final _HostOrders hostOwned = _HostOrders();
      getIt.registerSingleton<CourierOrdersRepositoryFacade>(hostOwned);
      DriverDeliveryDependencies.register(getIt);

      await DemoSession.instance.activate();
      expect(getIt.get<CourierOrdersRepositoryFacade>(), same(hostOwned));
      expect(getIt.get<CourierParcelRepositoryFacade>(),
          isA<DemoCourierParcelRepository>());

      await DemoSession.instance.clear();
      expect(getIt.get<CourierOrdersRepositoryFacade>(), same(hostOwned));
      expect(getIt.get<CourierParcelRepositoryFacade>(),
          isA<CourierParcelRepository>());
    });

    test('a second register on the same container is a no-op, and one flip '
        'still swaps once', () async {
      DriverDeliveryDependencies.register(getIt);
      final CourierRepositoryFacade first = getIt.get<CourierRepositoryFacade>();
      DriverDeliveryDependencies.register(getIt);
      expect(getIt.get<CourierRepositoryFacade>(), same(first));

      await DemoSession.instance.activate();
      _expectDemo(getIt);
      await DemoSession.instance.clear();
      _expectReal(getIt);
    });

    test('a boot that restores an active session registers the demo twins',
        () async {
      await DemoSession.instance.activate();
      DriverDeliveryDependencies.register(getIt);
      _expectDemo(getIt);

      await DemoSession.instance.clear();
      _expectReal(getIt);
    });

    test('a demo build registers the demo twins whatever the session says',
        () {
      DemoSession.isDemoOverride = true;
      DriverDeliveryDependencies.register(getIt);
      _expectDemo(getIt);
    });
  });

  group('CourierLocationFix.pinnedBuild', () {
    test('follows the runtime session per read', () async {
      expect(CourierLocationFix.pinnedBuild, isFalse);
      await DemoSession.instance.activate();
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

    test('no AppConstants.isDemo read remains in lib/ or templates/', () {
      final List<String> offenders = <String>[
        for (final file in [
          ...dartFilesUnder('lib'),
          ...dartFilesUnder('templates'),
        ])
          if (file.readAsStringSync().contains('AppConstants.isDemo'))
            file.path,
      ];
      expect(offenders, isEmpty);
    });

    test('every demo seam asks DemoSession.demoActive', () {
      const List<String> seams = <String>[
        'lib/src/driver/di/driver_delivery_di.dart',
        'lib/src/driver/presentation/launcher/driver_launch_window.dart',
        'lib/src/driver/infrastructure/services/courier_location_fix.dart',
        'templates/pages/driver/profile/profile_page.dart',
      ];
      for (final String seam in seams) {
        expect(File(seam).readAsStringSync(), contains('DemoSession.demoActive'),
            reason: seam);
      }
    });

    test('the installed profile page gates delete-account on the session',
        () {
      final String src =
          File('templates/pages/driver/profile/profile_page.dart')
              .readAsStringSync();
      expect(src, contains('DemoSession.demoActive ? null : _openDeleteAccount'));
      expect(src, contains("import 'package:base_sdk/src/services/demo_session.dart';"));
    });
  });
}
