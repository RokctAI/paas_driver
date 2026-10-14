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

// AppHelpers.goHome lands on the main screen when a single-shop build
// asks for a shop page the app does not have (launcher, manager, driver,
// supacharge never declare one), instead of throwing.

import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/navigation/app_routes.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers replaceMainRoute and, when [hasShop], replaceShopRoute; anything
/// else throws the StateError the generated host does.
class _Routes implements AppRoutes {
  _Routes({required this.hasShop});

  final bool hasShop;
  final List<String> calls = <String>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName.toString();
    if (name.contains('replaceMainRoute')) {
      calls.add('main');
      return Future<Object?>.value();
    }
    if (hasShop && name.contains('replaceShopRoute')) {
      calls.add('shop');
      return Future<Object?>.value();
    }
    throw StateError('AppRoutes.I.$name has not been implemented');
  }
}

Future<void> _goHome(WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Builder(builder: (context) {
      AppHelpers.goHome(context);
      return const SizedBox.shrink();
    }),
  ));
}

void main() {
  final original = AppConstants.enableMarketplace;
  tearDown(() => AppConstants.enableMarketplace = original);

  testWidgets('marketplace: main screen', (tester) async {
    final routes = _Routes(hasShop: true);
    AppRoutes.I = routes;
    AppConstants.enableMarketplace = true;
    await _goHome(tester);
    expect(routes.calls, ['main']);
  });

  testWidgets('single shop with a shop page: the shop', (tester) async {
    final routes = _Routes(hasShop: true);
    AppRoutes.I = routes;
    AppConstants.enableMarketplace = false;
    await _goHome(tester);
    expect(routes.calls, ['shop']);
  });

  testWidgets('single shop without a shop page: main screen, no crash',
      (tester) async {
    final routes = _Routes(hasShop: false);
    AppRoutes.I = routes;
    AppConstants.enableMarketplace = false;
    await _goHome(tester);
    expect(routes.calls, ['main']);
  });
}
