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

// The role DI hooks follow the RUNTIME demo switch.
//
// Until 1.13.0 each hook picked its statistics facade with a compile-time
// ternary on `AppConstants.isDemo`, so a server-marked demo account signing
// in on the production backend (base_sdk's `DemoSession`, phase 1) got the
// real HTTP facade and an empty income page. The hooks now read
// `DemoSession.demoActive` at registration AND swap the registration in
// place when the session flips - after login, before routing, and back on
// sign-out. These cases drive the shared GetIt singleton the generated
// main.dart's hook bodies target (fleet precedent: role_di_hooks_test) on
// the same SharedPreferences harness the sibling widget tests use, with
// `DemoSession.isDemoOverride = false` standing in for a production build.
//
// The last group is the source contract: no `AppConstants.isDemo` read may
// remain in this SDK's Dart. The one question every demo seam asks from
// here on is `DemoSession.demoActive`.

import 'dart:io';

import 'package:base_sdk/src/services/demo_session.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:revenue_sdk/src/common/domain/interface/courier_statistics.dart';
import 'package:revenue_sdk/src/common/domain/interface/deposit_approval.dart';
import 'package:revenue_sdk/src/common/domain/interface/driver_payout.dart';
import 'package:revenue_sdk/src/common/domain/interface/driver_wallet.dart';
import 'package:revenue_sdk/src/common/domain/interface/seller_statistics.dart';
import 'package:revenue_sdk/src/driver/di/driver_revenue_di.dart';
import 'package:revenue_sdk/src/driver/infrastructure/repositories/courier_statistics_repository.dart';
import 'package:revenue_sdk/src/driver/infrastructure/repositories/demo_courier_statistics_repository.dart';
import 'package:revenue_sdk/src/manager/di/manager_revenue_di.dart';
import 'package:revenue_sdk/src/manager/infrastructure/repositories/demo_seller_statistics_repository.dart';
import 'package:revenue_sdk/src/manager/infrastructure/repositories/seller_statistics_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final getIt = GetIt.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    // A production build: only the session half of the switch can flip.
    DemoSession.isDemoOverride = false;
  });

  tearDown(() async {
    DriverRevenueDependencies.resetDemoSessionListener();
    ManagerRevenueDependencies.resetDemoSessionListener();
    await DemoSession.instance.clear();
    // The override is app-global; never let one test leak into the next.
    DemoSession.isDemoOverride = null;
    await getIt.reset();
  });

  group('DriverRevenueDependencies', () {
    test('registers the real courier facade for a real account', () {
      DriverRevenueDependencies.register(getIt);
      expect(
        getIt<CourierStatisticsRepositoryFacade>(),
        isA<CourierStatisticsRepository>(),
      );
    });

    test('swaps to the demo twin when the session activates after boot',
        () async {
      DriverRevenueDependencies.register(getIt);
      await DemoSession.instance.activate();
      expect(
        getIt<CourierStatisticsRepositoryFacade>(),
        isA<DemoCourierStatisticsRepository>(),
      );
    });

    test('swaps back to the real facade when the session clears', () async {
      DriverRevenueDependencies.register(getIt);
      await DemoSession.instance.activate();
      await DemoSession.instance.clear();
      expect(
        getIt<CourierStatisticsRepositoryFacade>(),
        isA<CourierStatisticsRepository>(),
      );
    });

    test('registers the demo twin when the session is already active',
        () async {
      await DemoSession.instance.activate();
      DriverRevenueDependencies.register(getIt);
      expect(
        getIt<CourierStatisticsRepositoryFacade>(),
        isA<DemoCourierStatisticsRepository>(),
      );
    });

    test('registers the demo twin in a demo build whatever the session',
        () {
      DemoSession.isDemoOverride = true;
      DriverRevenueDependencies.register(getIt);
      expect(
        getIt<CourierStatisticsRepositoryFacade>(),
        isA<DemoCourierStatisticsRepository>(),
      );
    });

    test('a flip leaves the facades without a demo twin untouched',
        () async {
      DriverRevenueDependencies.register(getIt);
      final payout = getIt<DriverPayoutRepositoryFacade>();
      final wallet = getIt<DriverWalletRepositoryFacade>();
      await DemoSession.instance.activate();
      expect(identical(getIt<DriverPayoutRepositoryFacade>(), payout), isTrue);
      expect(identical(getIt<DriverWalletRepositoryFacade>(), wallet), isTrue);
    });

    test('a second register() call does not subscribe twice', () async {
      DriverRevenueDependencies.register(getIt);
      DriverRevenueDependencies.register(getIt);
      // A duplicate listener would re-register twice per flip; the second
      // registerSingleton of an already-registered type throws, which
      // would surface here as an uncaught error from notifyListeners.
      await DemoSession.instance.activate();
      expect(
        getIt<CourierStatisticsRepositoryFacade>(),
        isA<DemoCourierStatisticsRepository>(),
      );
      await DemoSession.instance.clear();
      expect(
        getIt<CourierStatisticsRepositoryFacade>(),
        isA<CourierStatisticsRepository>(),
      );
    });
  });

  group('ManagerRevenueDependencies', () {
    test('registers the real seller facade for a real account', () {
      ManagerRevenueDependencies.register(getIt);
      expect(
        getIt<SellerStatisticsRepositoryFacade>(),
        isA<SellerStatisticsRepository>(),
      );
    });

    test('swaps to the demo twin when the session activates after boot',
        () async {
      ManagerRevenueDependencies.register(getIt);
      await DemoSession.instance.activate();
      expect(
        getIt<SellerStatisticsRepositoryFacade>(),
        isA<DemoSellerStatisticsRepository>(),
      );
    });

    test('swaps back to the real facade when the session clears', () async {
      ManagerRevenueDependencies.register(getIt);
      await DemoSession.instance.activate();
      await DemoSession.instance.clear();
      expect(
        getIt<SellerStatisticsRepositoryFacade>(),
        isA<SellerStatisticsRepository>(),
      );
    });

    test('registers the demo twin when the session is already active',
        () async {
      await DemoSession.instance.activate();
      ManagerRevenueDependencies.register(getIt);
      expect(
        getIt<SellerStatisticsRepositoryFacade>(),
        isA<DemoSellerStatisticsRepository>(),
      );
    });

    test('registers the demo twin in a demo build whatever the session',
        () {
      DemoSession.isDemoOverride = true;
      ManagerRevenueDependencies.register(getIt);
      expect(
        getIt<SellerStatisticsRepositoryFacade>(),
        isA<DemoSellerStatisticsRepository>(),
      );
    });

    test('a flip leaves the facades without a demo twin untouched',
        () async {
      ManagerRevenueDependencies.register(getIt);
      final payout = getIt<DriverPayoutRepositoryFacade>();
      final approvals = getIt<DepositApprovalRepositoryFacade>();
      await DemoSession.instance.activate();
      expect(identical(getIt<DriverPayoutRepositoryFacade>(), payout), isTrue);
      expect(
        identical(getIt<DepositApprovalRepositoryFacade>(), approvals),
        isTrue,
      );
    });

    test('a second register() call does not subscribe twice', () async {
      ManagerRevenueDependencies.register(getIt);
      ManagerRevenueDependencies.register(getIt);
      await DemoSession.instance.activate();
      expect(
        getIt<SellerStatisticsRepositoryFacade>(),
        isA<DemoSellerStatisticsRepository>(),
      );
      await DemoSession.instance.clear();
      expect(
        getIt<SellerStatisticsRepositoryFacade>(),
        isA<SellerStatisticsRepository>(),
      );
    });
  });

  group('both role hooks composed in one host', () {
    test('each swaps its own facade on the same flip', () async {
      ManagerRevenueDependencies.register(getIt);
      DriverRevenueDependencies.register(getIt);
      await DemoSession.instance.activate();
      expect(
        getIt<SellerStatisticsRepositoryFacade>(),
        isA<DemoSellerStatisticsRepository>(),
      );
      expect(
        getIt<CourierStatisticsRepositoryFacade>(),
        isA<DemoCourierStatisticsRepository>(),
      );
      await DemoSession.instance.clear();
      expect(
        getIt<SellerStatisticsRepositoryFacade>(),
        isA<SellerStatisticsRepository>(),
      );
      expect(
        getIt<CourierStatisticsRepositoryFacade>(),
        isA<CourierStatisticsRepository>(),
      );
    });
  });

  group('source contract', () {
    // `flutter test` runs with the package directory as its working
    // directory, so `lib/` sits right next to `pubspec.yaml`.
    test('no AppConstants.isDemo read remains in lib/', () {
      final offenders = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final lines = entity.readAsStringSync().split('\n');
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          // Comments may still NAME the constant when they explain the
          // history of the split; only code reads are the contract.
          if (line.trimLeft().startsWith('//')) continue;
          if (line.contains('AppConstants.isDemo')) {
            offenders.add('${entity.path}:${i + 1}');
          }
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'every demo seam reads DemoSession.demoActive so a demo '
            'session on the production backend is served from the fixtures '
            'too; found compile-time reads at $offenders',
      );
    });

    test('both role DI hooks read the runtime switch', () {
      for (final path in const [
        'lib/src/driver/di/driver_revenue_di.dart',
        'lib/src/manager/di/manager_revenue_di.dart',
      ]) {
        final source = File(path).readAsStringSync();
        expect(source, contains('DemoSession.demoActive'), reason: path);
        expect(
          source,
          contains('DemoSession.instance.addListener'),
          reason: '$path must re-register when the session flips',
        );
      }
    });
  });
}
