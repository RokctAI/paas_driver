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

// FRAMES 53f and 53l of design strip section 53 - the manager window on
// the launcher canvas.
//
// What a later edit could quietly undo, and what each group pins:
//
//   * the window never draws a takings figure. Chip 1289 omits it as the
//     frame's extension of the 53e money ruling, so the rendered text is
//     checked for a currency mark and for the words that would announce
//     one;
//   * the count is the only figure, and a read that fails draws no
//     number rather than a zero nobody measured;
//   * the dataless state is still useful and tappable - the action
//     alone, no count;
//   * the loader reads the same facade the order board reads, the demo
//     seed included, and a failing facade is a null queue, not a throw;
//   * the manifest carries the injection under launch_sdk's markers with
//     the exact placeholder strings the composer substring-matches.

import 'dart:convert';
import 'dart:io';

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/response/orders_paginate_response.dart';
import 'package:orders_sdk/src/manager/infrastructure/repositories/demo_seller_orders_repository.dart';
import 'package:orders_sdk/src/manager/presentation/launcher/manager_launch_window.dart';
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

/// A facade that answers the board's envelope with a statistic block and
/// a page of orders - the shape the count is read from. Everything else
/// is unreachable on purpose: the loader must touch nothing else.
class _CountingOrders implements SellerOrdersRepositoryFacade {
  _CountingOrders(this.count);

  final int count;
  final List<OrderStatus?> asked = <OrderStatus?>[];

  @override
  Future<ApiResult<OrdersPaginateResponse>> getOrders({
    OrderStatus? status,
    String? rawStatus,
    int? page,
    String? from,
    String? to,
  }) async {
    asked.add(status);
    return ApiResult.success(
      data: OrdersPaginateResponse.fromJson(<String, dynamic>{
        'data': <String, dynamic>{
          'statistic': <String, dynamic>{'new_orders_count': count},
          'orders': <dynamic>[],
        },
      }),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// A facade whose read fails like an unreachable backend.
class _FailingOrders implements SellerOrdersRepositoryFacade {
  @override
  Future<ApiResult<OrdersPaginateResponse>> getOrders({
    OrderStatus? status,
    String? rawStatus,
    int? page,
    String? from,
    String? to,
  }) async =>
      const ApiResult.failure(error: 'offline', statusCode: 503);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// A facade that throws outright - the launcher must survive that too.
class _ThrowingOrders implements SellerOrdersRepositoryFacade {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('no backend');
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocalStorage.init();
  });

  group('populated - chip 1256, the one window', () {
    testWidgets('the headline, the count waiting on you, and Open orders', (
      tester,
    ) async {
      var opened = 0;
      await _pump(
        tester,
        ManagerLaunchWindow(
          queue: const ManagerLaunchQueue(waiting: 3),
          onOpen: () => opened++,
        ),
      );
      final rendered = _text(tester);
      expect(rendered, contains('Orders to accept'));
      expect(rendered, contains('Waiting on you'));
      expect(find.byKey(ManagerLaunchWindow.countKey), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Open orders'), findsOneWidget);

      await tester.tap(find.byKey(ManagerLaunchWindow.openKey));
      expect(opened, 1);
    });

    testWidgets(
        'chip 1289 - no takings: no currency mark, no sales, no '
        'takings, no revenue, no balance', (tester) async {
      await _pump(
        tester,
        ManagerLaunchWindow(
          queue: const ManagerLaunchQueue(waiting: 3),
          onOpen: () {},
        ),
      );
      // A rand amount is a capital R against a digit; no such pair here.
      expect(_text(tester), isNot(matches(RegExp(r'R\s?\d'))));
      final rendered = _text(tester).toLowerCase();
      expect(rendered, isNot(contains('zar')));
      for (final word in <String>[
        'sale',
        'taking',
        'revenue',
        'balance',
        'earn',
        'total',
      ]) {
        expect(rendered, isNot(contains(word)), reason: word);
      }
    });

    testWidgets('a count nobody read is not drawn as a zero', (tester) async {
      await _pump(
        tester,
        ManagerLaunchWindow(load: () async => null, onOpen: () {}),
      );
      expect(_text(tester), contains('Orders to accept'));
      expect(find.byKey(ManagerLaunchWindow.countKey), findsNothing);
      expect(find.text('0'), findsNothing);
      expect(find.byKey(ManagerLaunchWindow.openKey), findsOneWidget);
    });
  });

  group('dataless - chip 1288, the back seat', () {
    testWidgets('renders the action alone and stays tappable', (
      tester,
    ) async {
      var opened = 0;
      await _pump(
        tester,
        ManagerLaunchWindow.dataless(onOpen: () => opened++),
      );
      expect(find.byType(Text), findsOneWidget);
      expect(find.text('Open orders'), findsOneWidget);
      expect(find.byKey(ManagerLaunchWindow.countKey), findsNothing);
      await tester.tap(find.byKey(ManagerLaunchWindow.openKey));
      expect(opened, 1);
    });
  });

  group('ManagerLaunchWindowLoader - the order board\'s own facade', () {
    setUp(DemoSellerOrdersRepository.reset);
    tearDown(DemoSellerOrdersRepository.reset);

    test('asks for the new column and reads the statistic', () async {
      final facade = _CountingOrders(3);
      final queue = await ManagerLaunchWindowLoader.load(repository: facade);
      expect(queue, isNotNull);
      expect(queue!.waiting, 3);
      expect(facade.asked, <OrderStatus?>[OrderStatus.open]);
    });

    test('the demo seed: the shift\'s two new orders', () async {
      final queue = await ManagerLaunchWindowLoader.load(
        repository: DemoSellerOrdersRepository(),
      );
      expect(queue, isNotNull);
      expect(queue!.waiting, 2);
    });

    test('a backend that answers failure is a null queue', () async {
      expect(
        await ManagerLaunchWindowLoader.load(repository: _FailingOrders()),
        isNull,
      );
    });

    test('a backend that throws is a null queue, never an exception', () async {
      expect(
        await ManagerLaunchWindowLoader.load(repository: _ThrowingOrders()),
        isNull,
      );
    });
  });

  group('manifest wiring - the injection under launch_sdk\'s markers', () {
    final manifest = jsonDecode(File('manifest.json').readAsStringSync())
        as Map<String, dynamic>;

    test('declares 1.20.0 and the launch_sdk floor', () {
      expect(manifest['version'], '1.20.0');
      expect(manifest['_comment_requires'], contains('launch_sdk >= 1.4.3'));
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
        "import 'package:orders_sdk/src/manager/presentation/launcher/"
        "manager_launch_window.dart';",
      );
      final window =
          byPlaceholder['                // @launcher-windows']!['replacement']
              as String;
      expect(window, contains('LaunchWindowSource.widget('));
      expect(window, contains('mode: LaunchMode.manager'));
      expect(window, contains('ManagerLaunchWindow(onOpen: openApp)'));
      // The launcher derives the package; nothing is named here.
      expect(window, isNot(contains('packageName')));
    });

    test('seeds the window\'s copy as top-level tr_keys', () {
      final keys = (manifest['tr_keys'] as Map).cast<String, String>();
      expect(
          keys.values,
          containsAll(<String>[
            ManagerLaunchWindowKeys.ordersToAccept,
            ManagerLaunchWindowKeys.waitingOnYou,
            ManagerLaunchWindowKeys.openOrders,
            'manager',
          ]));
    });
  });
}
