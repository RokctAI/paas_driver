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

// FRAME 53e of design strip section 53 - the driver window on the
// launcher canvas.
//
// What a later edit could quietly undo, and what each group pins:
//
//   * the window never draws money. The frame's fee and cash on hand
//     were REMOVED by ruling, not masked, so the rendered text is checked
//     for a currency mark and for the words that would announce one;
//   * the window never names a person or a street. The drop is a
//     suburb, reduced from the order's address line;
//   * the dataless state is still useful and tappable - the action
//     alone, nothing about any job;
//   * the loader reads the same facade the driver home reads, the demo
//     seed included, and a failing facade is a null job, not a throw;
//   * the manifest carries the injection under launch_sdk's markers with
//     the exact placeholder strings the composer substring-matches.

import 'dart:convert';
import 'dart:io';

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:delivery_sdk/src/driver/domain/interface/orders.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/order_detail.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/order_paginate_response.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/demo_courier_orders_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/demo_delivery_seed.dart';
import 'package:delivery_sdk/src/driver/presentation/launcher/driver_launch_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The launcher's window chrome is 390 wide less its margins; the content
/// is pumped at that width so the rows lay out as they will on the canvas.
Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(28), child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Every rendered string, joined - the cheapest way to assert what the
/// window does and does not say.
String _text(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? '')
    .join(' | ');

const DriverLaunchJob _waiting = DriverLaunchJob(
  id: '4211',
  shopName: 'Karoo Kitchen',
  dropSuburb: 'Lynnwood Ridge',
  pickupKm: 1.2,
  dropKm: 4.8,
);

/// A facade whose two reads fail like an unreachable backend. Everything
/// else is unreachable on purpose: the loader must touch nothing else.
class _FailingOrders implements CourierOrdersRepositoryFacade {
  @override
  Future<ApiResult<OrderPaginateResponse>> fetchCurrentOrder() async =>
      const ApiResult.failure(error: 'offline', statusCode: 503);

  @override
  Future<ApiResult<List<OrderDetailData>>> getAvailableOrders(int page) async =>
      const ApiResult.failure(error: 'offline', statusCode: 503);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// A facade that throws outright - the launcher must survive that too.
class _ThrowingOrders implements CourierOrdersRepositoryFacade {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('no backend');
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocalStorage.init();
  });

  group('populated - chip 1255, the one window', () {
    testWidgets(
        'a waiting job: headline, both legs with their distances, '
        'and Accept', (tester) async {
      var opened = 0;
      await _pump(
        tester,
        DriverLaunchWindow(job: _waiting, onOpen: () => opened++),
      );
      final rendered = _text(tester);
      expect(rendered, contains('Order waiting'));
      expect(rendered, contains('Pick up'));
      expect(rendered, contains('Karoo Kitchen'));
      expect(rendered, contains('1.2 km'));
      expect(rendered, contains('Drop'));
      expect(rendered, contains('Lynnwood Ridge'));
      expect(rendered, contains('4.8 km'));
      expect(find.byKey(DriverLaunchWindow.acceptKey), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);

      await tester.tap(find.byKey(DriverLaunchWindow.acceptKey));
      expect(opened, 1);
    });

    testWidgets(
        'chip 1291 - no money: no currency mark, no fee, no cash, '
        'no balance, no earnings', (tester) async {
      await _pump(tester, DriverLaunchWindow(job: _waiting, onOpen: () {}));
      // A rand amount is a capital R against a digit; no such pair here.
      expect(_text(tester), isNot(matches(RegExp(r'R\s?\d'))));
      final rendered = _text(tester).toLowerCase();
      expect(rendered, isNot(contains('zar')));
      for (final word in <String>['fee', 'cash', 'balance', 'earn', 'owe']) {
        expect(rendered, isNot(contains(word)), reason: word);
      }
    });

    testWidgets('a distance nobody computed is omitted, not guessed', (
      tester,
    ) async {
      await _pump(
        tester,
        DriverLaunchWindow(
          job: const DriverLaunchJob(
            id: '1',
            shopName: 'Karoo Kitchen',
            dropSuburb: 'Rosebank',
          ),
          onOpen: () {},
        ),
      );
      expect(_text(tester), isNot(contains('km')));
    });

    testWidgets('the job in hand reads as such and opens the app', (
      tester,
    ) async {
      var opened = 0;
      await _pump(
        tester,
        DriverLaunchWindow(
          job: const DriverLaunchJob(
            id: '1',
            shopName: 'Karoo Kitchen',
            dropSuburb: 'Rosebank',
            inHand: true,
          ),
          onOpen: () => opened++,
        ),
      );
      expect(_text(tester), contains('Job in hand'));
      expect(find.byKey(DriverLaunchWindow.acceptKey), findsNothing);
      await tester.tap(find.byKey(DriverLaunchWindow.openKey));
      expect(opened, 1);
    });

    testWidgets('no job: the no-job state and an Open, nothing invented', (
      tester,
    ) async {
      await _pump(
        tester,
        DriverLaunchWindow(load: () async => null, onOpen: () {}),
      );
      final rendered = _text(tester);
      expect(rendered, contains('No job right now'));
      expect(rendered, isNot(contains('km')));
      expect(find.byKey(DriverLaunchWindow.openKey), findsOneWidget);
    });
  });

  group('dataless - chip 1288, the back seat', () {
    testWidgets('renders the action alone and stays tappable', (
      tester,
    ) async {
      var opened = 0;
      await _pump(
        tester,
        DriverLaunchWindow.dataless(onOpen: () => opened++),
      );
      expect(find.byType(Text), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(_text(tester), isNot(contains('km')));
      expect(_text(tester), isNot(contains('Order')));
      await tester.tap(find.byKey(DriverLaunchWindow.openKey));
      expect(opened, 1);
    });
  });

  group('DriverLaunchJob - chip 1290, a shop and a suburb, no person', () {
    test('suburbOf keeps the last segment of the address line', () {
      expect(
          DriverLaunchJob.suburbOf('12 Cradock Avenue, Rosebank'), 'Rosebank');
      expect(DriverLaunchJob.suburbOf('Lynnwood Ridge'), 'Lynnwood Ridge');
      expect(DriverLaunchJob.suburbOf(' , '), isNull);
      expect(DriverLaunchJob.suburbOf(null), isNull);
    });

    test(
        'fromOrder derives the drop distance from the two points and the '
        'pick-up distance from the driver, and knows when it cannot', () {
      final order = OrderDetailData.fromJson(<String, dynamic>{
        'id': '7',
        'shop': <String, dynamic>{
          'location': <String, dynamic>{
            'latitude': '-26.1076',
            'longitude': '28.0567',
          },
          'translation': <String, dynamic>{'title': 'Karoo Kitchen'},
        },
        'location': <String, dynamic>{
          'latitude': '-26.1467',
          'longitude': '28.0400',
        },
        'address': <String, dynamic>{
          'address': '34 Jan Smuts Avenue, Rosebank',
        },
        'delivery_fee': 38.5,
        'total_price': 248.5,
      });

      final unknown = DriverLaunchJob.fromOrder(order, inHand: false);
      expect(unknown.shopName, 'Karoo Kitchen');
      expect(unknown.dropSuburb, 'Rosebank');
      expect(unknown.pickupKm, isNull);
      expect(unknown.dropKm, closeTo(4.6, 0.3));

      final known = DriverLaunchJob.fromOrder(
        order,
        inHand: false,
        driverLatitude: -26.0995,
        driverLongitude: 28.0556,
      );
      expect(known.pickupKm, closeTo(0.9, 0.2));
    });
  });

  group('DriverLaunchWindowLoader - the driver home\'s own facade', () {
    setUp(DemoDeliverySeed.reset);
    tearDown(DemoDeliverySeed.reset);

    test('the demo seed: the current order first, in hand', () async {
      final job = await DriverLaunchWindowLoader.load(
        repository: DemoCourierOrdersRepository(),
      );
      expect(job, isNotNull);
      expect(job!.inHand, isTrue);
      expect(job.id, DemoDeliverySeed.currentOrderId);
      expect(job.shopName, isNotEmpty);
      // A suburb, not the seed's street line.
      expect(job.dropSuburb, isNot(contains(',')));
      expect(job.dropSuburb, isNot(matches(RegExp(r'\d'))));
    });

    test('the demo seed with nothing in hand: the first job waiting', () async {
      DemoDeliverySeed.currentOrderId = null;
      final job = await DriverLaunchWindowLoader.load(
        repository: DemoCourierOrdersRepository(),
      );
      expect(job, isNotNull);
      expect(job!.inHand, isFalse);
      expect(job.shopName, isNotEmpty);
    });

    test('a backend that answers failure is a null job', () async {
      expect(
        await DriverLaunchWindowLoader.load(repository: _FailingOrders()),
        isNull,
      );
    });

    test('a backend that throws is a null job, never an exception', () async {
      expect(
        await DriverLaunchWindowLoader.load(repository: _ThrowingOrders()),
        isNull,
      );
    });
  });

  group('manifest wiring - the injection under launch_sdk\'s markers', () {
    final manifest = jsonDecode(File('manifest.json').readAsStringSync())
        as Map<String, dynamic>;

    test('declares at least 1.20.0 and the launch_sdk floor', () {
      // The window shipped in 1.20.0; later patch releases of this SDK
      // (1.20.1's driver-home timer guard, ...) still carry it, so this
      // is a floor, not a pin.
      final version = (manifest['version'] as String)
          .split('.')
          .map(int.parse)
          .toList(growable: false);
      expect(version.length, 3);
      expect(
        version[0] > 1 || (version[0] == 1 && version[1] >= 20),
        isTrue,
        reason: 'manifest declares ${manifest['version']}, before 1.20.0',
      );
      expect(manifest['_comment_requires_launcher'], contains('1.4.3'));
    });

    test(
        'injects the import and the window under the two markers, with '
        'the placeholders the composer substring-matches', () {
      final integrations =
          (manifest['integrations'] as List).cast<Map<String, dynamic>>();
      final byPlaceholder = <String, Map<String, dynamic>>{
        for (final entry in integrations) entry['placeholder'] as String: entry,
      };
      expect(
          byPlaceholder.keys,
          containsAll(<String>[
            '// @launcher-windows-imports',
            '                // @launcher-windows',
          ]));
      for (final entry in integrations) {
        expect(entry['target'], 'lib/presentation/pages/launch/home.dart');
      }
      expect(
        byPlaceholder['// @launcher-windows-imports']!['replacement'],
        "import 'package:delivery_sdk/src/driver/presentation/launcher/"
        "driver_launch_window.dart';",
      );
      final window =
          byPlaceholder['                // @launcher-windows']!['replacement']
              as String;
      expect(window, contains('LaunchWindowSource.widget('));
      expect(window, contains('mode: LaunchMode.driver'));
      expect(window, contains('DriverLaunchWindow(onOpen: openApp)'));
      // The launcher derives the package; nothing is named here.
      expect(window, isNot(contains('packageName')));
    });

    test('seeds the window\'s copy as top-level tr_keys', () {
      final keys = (manifest['tr_keys'] as Map).cast<String, String>();
      expect(
          keys.values,
          containsAll(<String>[
            DriverLaunchWindowKeys.orderWaiting,
            DriverLaunchWindowKeys.jobInHand,
            DriverLaunchWindowKeys.noJobRightNow,
            DriverLaunchWindowKeys.pickUp,
            DriverLaunchWindowKeys.drop,
          ]));
    });
  });
}
