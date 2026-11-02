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
//
// The till's unknown-barcode prompt (Ray: "it needs to tell user it doesnt
// recognised it whould you like to add this product?"; render approved
// 2026-10-30 19:22Z). A scan the catalog answers with no product pauses
// the camera and asks, pumped DIRECTLY from templates/ like the other POS
// tests (over the demo till, support/demo_till.dart):
//
//   * 393 (phone) and 700 (two-plane fold): the app's own bottom sheet
//     over the till;
//   * 1280 (three planes): the prompt takes the Add Items pane's place in
//     plane 2, the cart (plane 3) untouched;
//   * "Scan again" dismisses and resumes the camera; "Add this product"
//     closes the prompt and hands the code to the shell's callback;
//   * a known barcode still lands a cart line and asks nothing.

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/models/data/currency_data.dart';
import 'package:base_sdk/src/models/response/products_paginate_response.dart';
import 'package:base_sdk/src/presentation/adaptive/planes.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:merchants_sdk/src/manager/application/pos_cart/pos_cart_notifier.dart';
import 'package:merchants_sdk/src/manager/application/pos_cart/pos_cart_provider.dart';
import 'package:merchants_sdk/src/manager/domain/interface/pos_catalog.dart';
import 'package:merchants_sdk/src/manager/utils/pos_connectivity.dart';
import 'package:remixicon/remixicon.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../templates/pages/manager/billing/billing_page.dart';

import 'support/demo_till.dart';

/// The demo scan that lands the beef burger (the POS tests' own code).
const String _knownBarcode = '600123';

/// A real-looking EAN-13 the demo catalog does not carry.
const String _unknownBarcode = '6009880123457';

const _tillKey = ValueKey('plane-page-pos-till');
const _promptKey = Key('posUnknownBarcodePrompt');
const _promptPaneKey = Key('posUnknownBarcodePane');
const _addItemsPaneKey = Key('posAddItemsPane');
const _addKey = Key('posUnknownBarcodeAdd');
const _scanAgainKey = Key('posUnknownBarcodeScanAgain');

/// DemoTillCatalog answers every query with the beef burger, so no demo
/// code is ever unknown. The same catalog, except [_unknownBarcode] finds
/// nothing.
class _CatalogWithUnknownCode extends DemoTillCatalog {
  @override
  Future<ApiResult<ProductsPaginateResponse>> searchProducts({
    required String text,
    int page = 1,
    String? categoryId,
  }) async {
    if (text == _unknownBarcode) {
      return ApiResult.success(data: ProductsPaginateResponse(data: const []));
    }
    return super.searchProducts(text: text, page: page, categoryId: categoryId);
  }
}

Widget _host(Size size, {PosAddUnknownProduct? onAddUnknownProduct}) =>
    ProviderScope(
      child: ScreenUtilInit(
        // The app's own rule (base app_widget.dart): compact windows design
        // at 375x812, wider ones at their logical size.
        designSize: size.width < 600 ? const Size(375, 812) : size,
        builder: (context, _) => MaterialApp(
          home: BillingPage(onAddUnknownProduct: onAddUnknownProduct),
        ),
      ),
    );

Future<ProviderContainer> _pump(
  WidgetTester tester,
  Size size, {
  PosAddUnknownProduct? onAddUnknownProduct,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _host(size, onAddUnknownProduct: onAddUnknownProduct),
  );
  await tester.pump();
  final element = tester.element(find.byType(BillingPage));
  return ProviderScope.containerOf(element, listen: false);
}

/// Scans [barcode] the way the camera's onDetect does, then lets a sheet
/// finish opening.
Future<bool> _scan(
  WidgetTester tester,
  ProviderContainer container,
  String barcode,
) async {
  final added = await container
      .read(posCartProvider.notifier)
      .addByBarcode(barcode);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  return added;
}

/// The camera is paused: the stage shows its resume (play) control.
Finder get _paused => find.byIcon(Remix.play_line);
Finder get _live => find.byIcon(Remix.pause_line);

void _expectPromptCopy() {
  expect(find.text("We don't recognise this barcode"), findsOneWidget);
  expect(find.text(_unknownBarcode), findsOneWidget);
  expect(
    find.text(
      "It isn't in your products yet. Would you like to add this product?",
    ),
    findsOneWidget,
  );
  expect(find.text('Scan again'), findsOneWidget);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    await LocalStorage.setSelectedCurrency(
      CurrencyData(id: 'ZAR', symbol: 'R', position: 'before', rate: 1),
    );
    // Registered first, so registerDemoTill's guarded registration
    // stands aside.
    GetIt.I.registerSingleton<PosCatalogRepositoryFacade>(
      _CatalogWithUnknownCode(),
    );
    await registerDemoTill();
  });

  setUp(() => PosConnectivity.debugConnectivityOverride = true);
  tearDown(() => PosConnectivity.debugConnectivityOverride = null);

  testWidgets('393 (phone): an unknown scan pauses the camera and asks in a '
      'bottom sheet; the cart is untouched', (tester) async {
    final container = await _pump(
      tester,
      const Size(393, 852),
      onAddUnknownProduct: (_, __) {},
    );
    expect(Planes.of(tester.element(find.byKey(_tillKey))).count, 1);

    expect(await _scan(tester, container, _unknownBarcode), isFalse);

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byKey(_promptKey),
      ),
      findsOneWidget,
    );
    expect(find.byKey(_promptPaneKey), findsNothing);
    _expectPromptCopy();
    expect(find.byKey(_addKey), findsOneWidget);
    expect(_paused, findsOneWidget);
    expect(container.read(posCartProvider).unknownBarcode, _unknownBarcode);
    expect(container.read(posCartProvider).lines, isEmpty);
  });

  testWidgets('700 (two-plane fold): no Add Items pane shows, so the prompt '
      'is the bottom sheet there too', (tester) async {
    final container = await _pump(
      tester,
      const Size(700, 1000),
      onAddUnknownProduct: (_, __) {},
    );
    expect(Planes.of(tester.element(find.byKey(_tillKey))).count, 2);

    await _scan(tester, container, _unknownBarcode);

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byKey(_promptKey), findsOneWidget);
    expect(find.byKey(_promptPaneKey), findsNothing);
    _expectPromptCopy();
    expect(_paused, findsOneWidget);
  });

  testWidgets('1280 (three planes): the prompt takes the Add Items pane\'s '
      'place in plane 2 until answered; the cart stays in plane 3', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      const Size(1280, 800),
      onAddUnknownProduct: (_, __) {},
    );
    expect(Planes.of(tester.element(find.byKey(_tillKey))).count, 3);
    await _scan(tester, container, _knownBarcode);
    expect(find.byKey(_addItemsPaneKey), findsOneWidget);

    await _scan(tester, container, _unknownBarcode);

    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byKey(_promptPaneKey), findsOneWidget);
    expect(find.byKey(_addItemsPaneKey), findsNothing);
    _expectPromptCopy();
    expect(find.text('Cart'), findsOneWidget);
    expect(find.text('R150.00 × 1'), findsOneWidget);
    expect(_paused, findsOneWidget);
    // Plane order: scan | prompt | cart.
    final double promptX = tester.getTopLeft(find.byKey(_promptPaneKey)).dx;
    expect(
      promptX,
      greaterThan(tester.getTopLeft(find.byKey(const Key('posScanStage'))).dx),
    );
    expect(promptX, lessThan(tester.getTopLeft(find.text('Cart')).dx));

    await tester.tap(find.byKey(_scanAgainKey));
    await tester.pump();

    expect(find.byKey(_promptPaneKey), findsNothing);
    expect(find.byKey(_addItemsPaneKey), findsOneWidget);
    expect(_live, findsOneWidget);
    expect(container.read(posCartProvider).unknownBarcode, isNull);
  });

  testWidgets('Scan again closes the sheet and resumes scanning; the same '
      'code scanned at once asks again', (tester) async {
    final container = await _pump(tester, const Size(393, 852));
    await _scan(tester, container, _unknownBarcode);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(_paused, findsOneWidget);

    await tester.tap(find.byKey(_scanAgainKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byKey(_promptKey), findsNothing);
    expect(_live, findsOneWidget);
    expect(container.read(posCartProvider).unknownBarcode, isNull);

    // Inside the dedupe window, but the answer reset it: a new scan.
    await _scan(tester, container, _unknownBarcode);
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('swiping the sheet away answers it too', (tester) async {
    final container = await _pump(tester, const Size(393, 852));
    await _scan(tester, container, _unknownBarcode);
    expect(find.byType(BottomSheet), findsOneWidget);

    // The barrier above the sheet.
    await tester.tapAt(const Offset(196, 20));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(BottomSheet), findsNothing);
    expect(container.read(posCartProvider).unknownBarcode, isNull);
  });

  testWidgets('Add this product closes the prompt and calls the shell once '
      'with the scanned code', (tester) async {
    final calls = <String>[];
    final container = await _pump(
      tester,
      const Size(393, 852),
      onAddUnknownProduct: (context, barcode) => calls.add(barcode),
    );
    await _scan(tester, container, _unknownBarcode);

    await tester.tap(find.byKey(_addKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(calls, [_unknownBarcode]);
    expect(find.byType(BottomSheet), findsNothing);
    expect(container.read(posCartProvider).unknownBarcode, isNull);
    // The attendant is in the add-product form: the camera stays paused.
    expect(_paused, findsOneWidget);
  });

  testWidgets('Add this product in the plane-2 prompt calls the shell and '
      'gives the pane back', (tester) async {
    final calls = <String>[];
    final container = await _pump(
      tester,
      const Size(1280, 800),
      onAddUnknownProduct: (context, barcode) => calls.add(barcode),
    );
    await _scan(tester, container, _unknownBarcode);

    await tester.tap(find.byKey(_addKey));
    await tester.pump();

    expect(calls, [_unknownBarcode]);
    expect(find.byKey(_promptPaneKey), findsNothing);
    expect(find.byKey(_addItemsPaneKey), findsOneWidget);
  });

  testWidgets('no create-product form composed: the prompt offers Scan again '
      'only', (tester) async {
    final container = await _pump(tester, const Size(393, 852));
    await _scan(tester, container, _unknownBarcode);

    expect(find.byKey(_promptKey), findsOneWidget);
    expect(find.byKey(_addKey), findsNothing);
    expect(find.byKey(_scanAgainKey), findsOneWidget);
  });

  // At three planes only: under the test font a cart line overflows the
  // cart header of the phone and two-plane layouts (real fonts fit - the
  // approved render reported no overflow; the existing 800 plane-flow
  // test hits the same header). The notifier test below covers the lane
  // itself at every width.
  testWidgets('1280: a known barcode still adds to the cart and asks nothing', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      const Size(1280, 800),
      onAddUnknownProduct: (_, __) {},
    );

    expect(await _scan(tester, container, _knownBarcode), isTrue);

    expect(container.read(posCartProvider).lines, hasLength(1));
    expect(container.read(posCartProvider).unknownBarcode, isNull);
    expect(find.text('R150.00 × 1'), findsOneWidget);
    expect(find.byKey(_promptKey), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);
    expect(_live, findsOneWidget);
  });

  test('the notifier keeps the unknown code until it is dismissed', () async {
    final notifier = PosCartNotifier(_CatalogWithUnknownCode());
    addTearDown(notifier.dispose);

    expect(await notifier.addByBarcode(_unknownBarcode), isFalse);
    expect(notifier.state.unknownBarcode, _unknownBarcode);
    expect(notifier.state.lines, isEmpty);

    notifier.dismissUnknownBarcode();
    expect(notifier.state.unknownBarcode, isNull);

    expect(await notifier.addByBarcode(_knownBarcode), isTrue);
    expect(notifier.state.unknownBarcode, isNull);
    expect(notifier.state.lines, hasLength(1));
  });
}
