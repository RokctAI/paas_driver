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

// The till's approved plane layout (design strip section 11, frames 11m
// approved 2026-08-29 13:53Z and 11n approved 13:06Z, on base_sdk's
// PlaneHost), pumped DIRECTLY from templates/ like the other POS tests
// (run with --dart-define=IS_DEMO=true):
//
//   * 1280 (three planes): the till declares ALL — scan | Add Items pane
//     | cart, no Add Items lane (277 removed, 11m); Continue pushes the
//     checkout INTO the planes claiming two — the till yields to its scan
//     plane WITH the lane (11n plane 1), the checkout spreads order truth
//     | tender over planes 2–3, the host's back pill sits at the
//     bottom-END corner (12d) and pops it;
//   * 800 (two planes): scan | cart with the lane (no pane shows); the
//     checkout's two-plane claim takes the whole fold, the till slides
//     off, END pill pops it back;
//   * 393 (phone): the shipped one-column page, no plane machinery in
//     sight — the checkout stays the pushed route.

import 'package:base_sdk/src/models/data/currency_data.dart';
import 'package:base_sdk/src/presentation/adaptive/planes.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:merchants_sdk/src/manager/application/pos_cart/pos_cart_provider.dart';
import 'package:merchants_sdk/src/manager/di/manager_merchants_di.dart';
import 'package:merchants_sdk/src/manager/utils/pos_connectivity.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../templates/pages/manager/billing/billing_page.dart';
import '../templates/pages/manager/billing/checkout_page.dart';

const _tillKey = ValueKey('plane-page-pos-till');
const _checkoutKey = ValueKey('plane-page-pos-checkout');
const _laneKey = Key('posAddItemsLane');
const _paneKey = Key('posAddItemsPane');
const _stageKey = Key('posScanStage');

Widget _host(Size size) => ProviderScope(
      child: ScreenUtilInit(
        // The app's own rule (base app_widget.dart): tablet-mode windows
        // use their logical size as the design size — scale 1.
        designSize: size,
        builder: (context, _) => const MaterialApp(home: BillingPage()),
      ),
    );

Future<ProviderContainer> _pump(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_host(size));
  await tester.pump();
  final element = tester.element(find.byType(BillingPage));
  return ProviderScope.containerOf(element, listen: false);
}

Planes _planesOf(WidgetTester tester, Key pageKey) =>
    Planes.of(tester.element(find.byKey(pageKey)));

/// Continue (287) carries "•  total"; the total alone also appears on
/// the summary and the line card.
Finder get _continueButton => find.textContaining('•');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    await LocalStorage.setSelectedCurrency(
      CurrencyData(id: 'ZAR', symbol: 'R', position: 'before', rate: 1),
    );
    ManagerMerchantsDependencies.register(GetIt.instance);
  });

  setUp(() => PosConnectivity.debugConnectivityOverride = true);
  tearDown(() => PosConnectivity.debugConnectivityOverride = null);

  testWidgets(
      '393 (phone): one plane, the shipped column — lane present, no '
      'pane, no pill, no in-plane checkout', (tester) async {
    await _pump(tester, const Size(393, 852));

    final planes = _planesOf(tester, _tillKey);
    expect(planes.count, 1);
    expect(planes.span, 1);
    expect(find.byKey(_stageKey), findsOneWidget);
    expect(find.byKey(_laneKey), findsOneWidget);
    expect(find.byKey(_paneKey), findsNothing);
    expect(find.text('Cart'), findsOneWidget);
    expect(find.byType(CheckoutPage), findsNothing);
    expect(find.byType(FloatingBackPill), findsNothing);
  });

  testWidgets(
      '800 (two planes): scan | cart with the lane; Continue takes the '
      'fold for the checkout, the END pill pops it back', (tester) async {
    const size = Size(800, 1280);
    final container = await _pump(tester, size);

    var till = _planesOf(tester, _tillKey);
    expect(till.count, 2);
    expect(till.span, 2);
    expect(till.index, 0);
    expect(find.byKey(_laneKey), findsOneWidget);
    expect(find.byKey(_paneKey), findsNothing);
    expect(find.text('Cart'), findsOneWidget);
    expect(find.byType(FloatingBackPill), findsNothing);

    await container.read(posCartProvider.notifier).addByBarcode('600123');
    await tester.pump();
    expect(find.text('R150.00 × 1'), findsOneWidget);

    await tester.tap(_continueButton);
    await tester.pump();
    await tester.pump();

    // 11n's claim of two at a two-plane fold: the checkout holds both,
    // the till slides off (min(claim, count) — the plane model's rule).
    expect(find.byType(CheckoutPage), findsOneWidget);
    expect(find.byKey(_tillKey), findsNothing);
    final checkout = _planesOf(tester, _checkoutKey);
    expect(checkout.count, 2);
    expect(checkout.span, 2);
    expect(checkout.index, 0);
    expect(checkout.isLast, isTrue);
    // Spread: title in the order-truth column, finish in the tender one.
    expect(find.text('Checkout'), findsOneWidget);
    expect(find.textContaining('Finish'), findsWidgets);
    expect(find.text('R150.00'), findsWidgets);

    // ONE back affordance — the host's pill, at the bottom-END corner.
    expect(find.byType(FloatingBackPill), findsOneWidget);
    expect(find.byType(FloatingBottomNav), findsNothing);
    final pill = tester.getRect(find.byType(FloatingBackPill));
    expect(pill.right, closeTo(size.width - 16, 0.5));
    expect(pill.bottom, closeTo(size.height - 16, 0.5));

    await tester.tap(find.byType(FloatingBackPill));
    await tester.pump();
    expect(find.byType(CheckoutPage), findsNothing);
    till = _planesOf(tester, _tillKey);
    expect(till.span, 2);
    expect(find.text('R150.00 × 1'), findsOneWidget);
  });

  testWidgets(
      '1280 (three planes): scan | Add Items pane | cart, no lane; the '
      'pane adds without closing; Continue — till yields to the scan '
      'plane with the lane, checkout spreads over planes 2–3, END pill',
      (tester) async {
    const size = Size(1280, 800);
    await _pump(tester, size);

    var till = _planesOf(tester, _tillKey);
    expect(till.count, 3);
    expect(till.span, 3);
    expect(find.byKey(_stageKey), findsOneWidget);
    expect(find.byKey(_laneKey), findsNothing);
    expect(find.byKey(_paneKey), findsOneWidget);
    expect(find.text('Cart'), findsOneWidget);
    expect(find.byType(FloatingBackPill), findsNothing);
    // The pane is part of a top-level page: no pill of its own (321 is
    // the SHEET's).
    expect(find.byType(FloatingBottomNav), findsNothing);

    // 318/319/320: search in the pane, one-tap add — the pane stays up.
    await tester.enterText(
      find.byKey(const Key('posAddItemsSearchField')),
      '600123',
    );
    await tester.pump(const Duration(milliseconds: 400)); // debounce
    await tester.pump();
    expect(find.text('Demo Product'), findsOneWidget); // the result row
    await tester.tap(find.text('Demo Product'));
    await tester.pump();
    expect(find.byKey(_paneKey), findsOneWidget);
    expect(find.text('R150.00 × 1'), findsOneWidget); // the cart line

    await tester.tap(_continueButton);
    await tester.pump();
    await tester.pump();

    expect(find.byType(CheckoutPage), findsOneWidget);
    till = _planesOf(tester, _tillKey);
    expect(till.count, 3);
    expect(till.span, 1);
    expect(till.index, 0);
    final checkout = _planesOf(tester, _checkoutKey);
    expect(checkout.span, 2);
    expect(checkout.index, 1);
    expect(checkout.isLast, isTrue);
    // 11n plane 1: the yielded till — scan stage + the Add Items lane;
    // the pane and the cart are gone with the planes they held.
    expect(find.byKey(_stageKey), findsOneWidget);
    expect(find.byKey(_laneKey), findsOneWidget);
    expect(find.byKey(_paneKey), findsNothing);
    expect(find.text('Cart'), findsNothing);
    expect(find.text('Checkout'), findsOneWidget);
    expect(find.textContaining('Finish'), findsWidgets);

    expect(find.byType(FloatingBackPill), findsOneWidget);
    expect(find.byType(FloatingBottomNav), findsNothing);
    final pill = tester.getRect(find.byType(FloatingBackPill));
    expect(pill.right, closeTo(size.width - 16, 0.5));
    expect(pill.bottom, closeTo(size.height - 16, 0.5));

    await tester.tap(find.byType(FloatingBackPill));
    await tester.pump();
    expect(find.byType(CheckoutPage), findsNothing);
    till = _planesOf(tester, _tillKey);
    expect(till.span, 3);
    expect(find.byKey(_paneKey), findsOneWidget);
    expect(find.byKey(_laneKey), findsNothing);
    expect(find.text('R150.00 × 1'), findsOneWidget);
  });
}
