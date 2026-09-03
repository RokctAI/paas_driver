// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// Role DI reaches the composed app.
//
// This SDK's role repositories are deliberately NOT registered by the common
// `RevenueSdkDependencies.register` (a role-stripped cache could not compile
// the import). They live in `lib/src/<role>/di/<role>_revenue_di.dart` and are
// reached ONLY through this manifest's `app_type.<role>.di_hooks`, which the
// installer injects into the composed app's generated `main.dart`.
//
// That makes the manifest entry load-bearing in a way the Dart analyzer cannot
// see: `ManagerRevenueDependencies` compiles perfectly while nothing on earth
// calls it. That is exactly what shipped — paas_manager's /income died on
// "GetIt: Object/factory with type SellerStatisticsRepositoryFacade is not
// registered inside GetIt" — and the same shape had already sunk paas_driver
// through delivery_sdk. So the guard here is structural rather than
// role-specific: EVERY role DI class this SDK defines must be named by a
// di_hooks body under its own role, with its direct `src/` import shipped
// alongside. Add `lib/src/<newrole>/di/...` without the manifest entry and
// this test fails before a composed app ever boots.
//
// The second group pins what the hook is for: calling register() really does
// put the facades the installed pages resolve into GetIt, and calling it twice
// (a host mid-migration that also wires it by hand) is harmless.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:revenue_sdk/src/common/domain/interface/courier_statistics.dart';
import 'package:revenue_sdk/src/common/domain/interface/driver_payout.dart';
import 'package:revenue_sdk/src/common/domain/interface/driver_wallet.dart';
import 'package:revenue_sdk/src/common/domain/interface/seller_statistics.dart';
import 'package:revenue_sdk/src/driver/di/driver_revenue_di.dart';
import 'package:revenue_sdk/src/manager/di/manager_revenue_di.dart';

/// `flutter test` runs with the package directory as its working directory,
/// so the manifest sits right next to `pubspec.yaml`.
Map<String, dynamic> _manifest() =>
    jsonDecode(File('manifest.json').readAsStringSync()) as Map<String, dynamic>;

List<Map<String, dynamic>> _hooksFor(Map<String, dynamic> manifest, String role) {
  final appType = (manifest['app_type'] as Map<String, dynamic>?) ?? const {};
  final block = (appType[role] as Map<String, dynamic>?) ?? const {};
  return ((block['di_hooks'] as List<dynamic>?) ?? const [])
      .cast<Map<String, dynamic>>();
}

void main() {
  group('manifest app_type.<role>.di_hooks reaches every role DI class', () {
    test('every lib/src/<role>/di class is called by its own role hook', () {
      final manifest = _manifest();
      final srcDir = Directory('lib/src');
      expect(srcDir.existsSync(), isTrue, reason: 'lib/src must exist');

      final found = <String, String>{}; // class name -> role
      for (final entity in srcDir.listSync()) {
        if (entity is! Directory) continue;
        final role = entity.uri.pathSegments
            .where((s) => s.isNotEmpty)
            .last;
        if (role == 'common') continue;
        final diDir = Directory('${entity.path}/di');
        if (!diDir.existsSync()) continue;
        for (final f in diDir.listSync()) {
          if (f is! File || !f.path.endsWith('.dart')) continue;
          for (final m in RegExp(r'^class (\w+)', multiLine: true)
              .allMatches(f.readAsStringSync())) {
            found[m.group(1)!] = role;
          }
        }
      }

      expect(
        found,
        isNotEmpty,
        reason: 'expected at least one lib/src/<role>/di class to guard',
      );

      found.forEach((className, role) {
        final hooks = _hooksFor(manifest, role);
        expect(
          hooks.any((h) => (h['body'] as String? ?? '')
              .contains('$className.register(GetIt.instance);')),
          isTrue,
          reason: '$className lives in lib/src/$role/di but no '
              'app_type.$role.di_hooks body calls it - a composed $role app '
              'would boot without its registrations and die at first resolve',
        );
        expect(
          hooks.any((h) => ((h['imports'] as List<dynamic>?) ?? const [])
              .cast<String>()
              .any((i) => i.contains('/src/$role/di/'))),
          isTrue,
          reason: 'app_type.$role.di_hooks must ship the direct src/ import '
              'for $className - the barrel deliberately does not export it',
        );
      });
    });

    test('manager and driver each declare exactly one role-DI hook id', () {
      final manifest = _manifest();
      expect(
        _hooksFor(manifest, 'manager').map((h) => h['id']),
        contains('revenue-manager-role-di'),
      );
      expect(
        _hooksFor(manifest, 'driver').map((h) => h['id']),
        contains('revenue-driver-role-di'),
      );
    });

    test('hook ids and orders are unique within a role', () {
      final manifest = _manifest();
      for (final role in const ['manager', 'driver']) {
        final hooks = _hooksFor(manifest, role);
        final ids = hooks.map((h) => h['id']).toList();
        expect(ids.toSet().length, ids.length,
            reason: 'duplicate di_hooks id in app_type.$role - the installer '
                'skips the later one');
        final orders = hooks.map((h) => h['order']).toList();
        expect(orders.toSet().length, orders.length,
            reason: 'duplicate di_hooks order in app_type.$role');
      }
    });
  });

  group('role register() puts the resolved facades into GetIt', () {
    // Fleet precedent (radio_sdk's tests): drive the shared GetIt singleton
    // and reset it between cases, rather than a private container — this is
    // the instance the generated main.dart's hook bodies actually target.
    final getIt = GetIt.instance;

    tearDown(() async {
      await getIt.reset();
    });

    test('ManagerRevenueDependencies registers SellerStatisticsRepositoryFacade',
        () {
      expect(getIt.isRegistered<SellerStatisticsRepositoryFacade>(), isFalse);
      ManagerRevenueDependencies.register(getIt);
      expect(getIt.isRegistered<SellerStatisticsRepositoryFacade>(), isTrue);
      expect(getIt<SellerStatisticsRepositoryFacade>(), isNotNull);
    });

    test('ManagerRevenueDependencies.register is idempotent', () {
      ManagerRevenueDependencies.register(getIt);
      final first = getIt<SellerStatisticsRepositoryFacade>();
      ManagerRevenueDependencies.register(getIt);
      expect(identical(getIt<SellerStatisticsRepositoryFacade>(), first), isTrue);
    });

    test(
        'ManagerRevenueDependencies registers the payout seam the manager '
        'wallet pane resolves (design strip frame 49l)', () {
      expect(getIt.isRegistered<DriverPayoutRepositoryFacade>(), isFalse);
      ManagerRevenueDependencies.register(getIt);
      expect(getIt.isRegistered<DriverPayoutRepositoryFacade>(), isTrue);
      expect(getIt<DriverPayoutRepositoryFacade>(), isNotNull);
    });

    test('DriverRevenueDependencies registers its three courier facades', () {
      DriverRevenueDependencies.register(getIt);
      expect(getIt.isRegistered<CourierStatisticsRepositoryFacade>(), isTrue);
      expect(getIt.isRegistered<DriverPayoutRepositoryFacade>(), isTrue);
      expect(getIt.isRegistered<DriverWalletRepositoryFacade>(), isTrue);
    });

    test('the two role hooks do not collide', () {
      ManagerRevenueDependencies.register(getIt);
      DriverRevenueDependencies.register(getIt);
      expect(getIt.isRegistered<SellerStatisticsRepositoryFacade>(), isTrue);
      expect(getIt.isRegistered<CourierStatisticsRepositoryFacade>(), isTrue);
      // Both hooks name the payout seam; the guard keeps the first.
      expect(getIt.isRegistered<DriverPayoutRepositoryFacade>(), isTrue);
    });
  });
}
