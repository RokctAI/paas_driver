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

// The demo repositories follow base_sdk's RUNTIME demo switch
// (DemoSession, base_sdk >= 1.61.0): the real repository with the switch
// off, the demo twin once a demo session is activated, the real one again
// once it is cleared - and the same answer for the launcher window's no-DI
// fallback. `DemoSession.isDemoOverride = false` pins the compile-time half
// so the suite reads the same with or without --dart-define=IS_DEMO=true.

import 'dart:io';

import 'package:base_sdk/src/domain/interface/cart.dart';
import 'package:base_sdk/src/domain/interface/orders.dart';
import 'package:base_sdk/src/services/demo_session.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:orders_sdk/src/common/di/orders_di.dart';
import 'package:orders_sdk/src/common/infrastructure/repositories/cart_repository.dart';
import 'package:orders_sdk/src/common/infrastructure/repositories/mock_cart_repository.dart';
import 'package:orders_sdk/src/common/infrastructure/repositories/mock_orders_repository.dart';
import 'package:orders_sdk/src/common/infrastructure/repositories/orders_repository.dart';
import 'package:orders_sdk/src/manager/di/manager_orders_di.dart';
import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';
import 'package:orders_sdk/src/manager/infrastructure/repositories/demo_seller_orders_repository.dart';
import 'package:orders_sdk/src/manager/infrastructure/repositories/seller_orders_repository.dart';
import 'package:orders_sdk/src/manager/presentation/launcher/manager_launch_window.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A host's own facade: the hook must never swap it, whichever way the
/// switch flips.
class _HostOrders implements OrdersRepositoryFacade {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  setUp(() async {
    DemoSession.isDemoOverride = false;
    await DemoSession.instance.clear();
  });

  tearDown(() async {
    await DemoSession.instance.clear();
    DemoSession.isDemoOverride = null;
  });

  group('OrdersSdkDependencies', () {
    test('switch off and no session: the real repositories', () {
      final getIt = GetIt.asNewInstance();
      OrdersSdkDependencies.register(getIt);
      expect(getIt<OrdersRepositoryFacade>(), isA<OrdersRepository>());
      expect(getIt<CartRepositoryFacade>(), isA<CartRepository>());
    });

    test(
      'activate swaps in the demo twins; clear swaps the real ones back',
      () async {
        final getIt = GetIt.asNewInstance();
        OrdersSdkDependencies.register(getIt);

        await DemoSession.instance.activate();
        expect(getIt<OrdersRepositoryFacade>(), isA<MockOrdersRepository>());
        expect(getIt<CartRepositoryFacade>(), isA<MockCartRepository>());

        await DemoSession.instance.clear();
        expect(getIt<OrdersRepositoryFacade>(), isA<OrdersRepository>());
        expect(getIt<CartRepositoryFacade>(), isA<CartRepository>());
      },
    );

    test(
      'a registration made while the session is already demo is the twin',
      () async {
        await DemoSession.instance.activate();
        final getIt = GetIt.asNewInstance();
        OrdersSdkDependencies.register(getIt);
        expect(getIt<OrdersRepositoryFacade>(), isA<MockOrdersRepository>());
        expect(getIt<CartRepositoryFacade>(), isA<MockCartRepository>());
      },
    );

    test('register is still idempotent, and a second call does not double '
        'the flip', () async {
      final getIt = GetIt.asNewInstance();
      OrdersSdkDependencies.register(getIt);
      final first = getIt<OrdersRepositoryFacade>();
      OrdersSdkDependencies.register(getIt);
      expect(identical(getIt<OrdersRepositoryFacade>(), first), isTrue);

      await DemoSession.instance.activate();
      expect(getIt<OrdersRepositoryFacade>(), isA<MockOrdersRepository>());
      await DemoSession.instance.clear();
      expect(getIt<OrdersRepositoryFacade>(), isA<OrdersRepository>());
    });

    test("a host's own facade is never swapped by a flip", () async {
      final getIt = GetIt.asNewInstance();
      final host = _HostOrders();
      getIt.registerSingleton<OrdersRepositoryFacade>(host);
      OrdersSdkDependencies.register(getIt);
      expect(identical(getIt<OrdersRepositoryFacade>(), host), isTrue);

      await DemoSession.instance.activate();
      expect(identical(getIt<OrdersRepositoryFacade>(), host), isTrue);
      // The cart, which the hook did register, still follows.
      expect(getIt<CartRepositoryFacade>(), isA<MockCartRepository>());

      await DemoSession.instance.clear();
      expect(identical(getIt<OrdersRepositoryFacade>(), host), isTrue);
    });
  });

  group('ManagerOrdersDependencies', () {
    test('switch off and no session: the real seller-orders repository', () {
      final getIt = GetIt.asNewInstance();
      ManagerOrdersDependencies.register(getIt);
      expect(
        getIt<SellerOrdersRepositoryFacade>(),
        isA<SellerOrdersRepository>(),
      );
    });

    test(
      'activate swaps in the demo shift; clear swaps the real one back',
      () async {
        final getIt = GetIt.asNewInstance();
        ManagerOrdersDependencies.register(getIt);

        await DemoSession.instance.activate();
        expect(
          getIt<SellerOrdersRepositoryFacade>(),
          isA<DemoSellerOrdersRepository>(),
        );

        await DemoSession.instance.clear();
        expect(
          getIt<SellerOrdersRepositoryFacade>(),
          isA<SellerOrdersRepository>(),
        );
      },
    );

    test(
      'a registration made while the session is already demo is the twin',
      () async {
        await DemoSession.instance.activate();
        final getIt = GetIt.asNewInstance();
        ManagerOrdersDependencies.register(getIt);
        expect(
          getIt<SellerOrdersRepositoryFacade>(),
          isA<DemoSellerOrdersRepository>(),
        );
      },
    );
  });

  group('ManagerLaunchWindowLoader fallback (no manager DI composed)', () {
    setUp(() {
      // The loader resolves through GetIt.instance; this file never
      // registers into it, so the fallback path is the one exercised.
      expect(
        GetIt.instance.isRegistered<SellerOrdersRepositoryFacade>(),
        isFalse,
      );
    });

    test('switch off and no session: no repository, so no queue', () async {
      expect(await ManagerLaunchWindowLoader.load(), isNull);
    });

    test('a demo session serves the seeded shift, read per call', () async {
      await DemoSession.instance.activate();
      final queue = await ManagerLaunchWindowLoader.load();
      expect(queue, isNotNull);
      expect(queue!.waiting, greaterThan(0));

      await DemoSession.instance.clear();
      expect(await ManagerLaunchWindowLoader.load(), isNull);
    });
  });

  group('source contract', () {
    test('no AppConstants.isDemo read remains in lib/ or templates/ - the '
        'demo seams ask DemoSession.demoActive', () {
      final hits = <String>[];
      for (final dir in const ['lib', 'templates']) {
        final root = Directory(dir);
        if (!root.existsSync()) continue;
        for (final file in root.listSync(recursive: true).whereType<File>()) {
          if (!file.path.endsWith('.dart')) continue;
          final lines = file.readAsLinesSync();
          for (var i = 0; i < lines.length; i++) {
            if (lines[i].contains('AppConstants.isDemo')) {
              hits.add('${file.path}:${i + 1}');
            }
          }
        }
      }
      expect(hits, isEmpty);
    });
  });
}
