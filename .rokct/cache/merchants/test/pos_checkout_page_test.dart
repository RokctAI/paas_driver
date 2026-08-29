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


// CheckoutPage (the POS checkout template) pumped DIRECTLY from
// templates/ (no ${package} imports by design — these tests are the
// template's compile gate; run with --dart-define=IS_DEMO=true).
//
// Covers the approved flows (strip frames 11c–11f): the Cash | QR method
// toggle with the QR card and online phase gate; the OFFLINE INVERSION
// (banner + straight-to-code entry, gate absent, QR still up) with the
// 6-digit code verified locally; and the dual finish — atomic
// print-then-record vs finish-without-receipt. PosConnectivity's
// debugConnectivityOverride seam pins each flow.

import 'package:base_sdk/src/models/data/currency_data.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:merchants_sdk/src/manager/application/pos_cart/pos_cart_provider.dart';
import 'package:merchants_sdk/src/manager/di/manager_merchants_di.dart';
import 'package:merchants_sdk/src/manager/utils/pos_connectivity.dart';
import 'package:merchants_sdk/src/manager/utils/pos_pay_verification.dart';
import 'package:merchants_sdk/src/manager/utils/pos_receipt_printer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../templates/pages/manager/billing/checkout_page.dart';

Widget _host(Widget child) => ProviderScope(
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, _) => MaterialApp(home: child),
      ),
    );

Future<ProviderContainer> _pumpWithCart(WidgetTester tester) async {
  // The render harness's geometry: 390 logical at 3x dpr, on the tall
  // canvas the approved checkout frames used (11e/11f are 390x1420), so
  // the whole flow - QR, code entry, both finish buttons - is laid out
  // without scrolling.
  tester.view.physicalSize = const Size(1170, 4260);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(_host(const CheckoutPage()));
  final element = tester.element(find.byType(CheckoutPage));
  final container = ProviderScope.containerOf(element, listen: false);
  await container.read(posCartProvider.notifier).addByBarcode('600123');
  await tester.pump(); // connectivity probe microtask + cart rebuild
  return container;
}

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

  tearDown(() {
    PosConnectivity.debugConnectivityOverride = null;
    PosReceiptPrinter.handler = null;
  });

  testWidgets(
      'online: the Cash | QR toggle drives the QR card and the '
      '"I\'ve Scanned" phase gate', (tester) async {
    PosConnectivity.debugConnectivityOverride = true;
    await _pumpWithCart(tester);

    // QR is the default method: pay-link QR card + phase gate up, no
    // offline banner, no code entry yet.
    expect(find.byKey(const Key('posPayQrCard')), findsOneWidget);
    expect(find.textContaining("I've Scanned"), findsOneWidget);
    expect(find.textContaining('Till offline'), findsNothing);
    expect(find.textContaining('Confirm by Code'), findsNothing);

    // The summary carries the formatted total.
    expect(find.text('R150.00'), findsWidgets);

    // Cash hides the whole QR flow.
    await tester.tap(find.text('Cash'));
    await tester.pump();
    expect(find.byKey(const Key('posPayQrCard')), findsNothing);
    expect(find.textContaining("I've Scanned"), findsNothing);

    // Back to QR: the gate returns; passing it reveals the code entry
    // (the customer's payment screen now shows the code).
    await tester.tap(find.textContaining('QR / Pay link'));
    await tester.pump();
    await tester.tap(find.textContaining("I've Scanned"));
    await tester.pump();
    expect(find.textContaining('Confirm by Code'), findsOneWidget);
  });

  testWidgets(
      'OFFLINE INVERSION: banner + straight-to-code entry (no phase '
      'gate), the QR stays, and the 6-digit code verifies locally',
      (tester) async {
    PosConnectivity.debugConnectivityOverride = false;
    final container = await _pumpWithCart(tester);

    // Banner up, code entry immediate, gate gone — and the QR card STAYS
    // (the customer's phone is online even when the till is not).
    expect(find.textContaining('Till offline'), findsOneWidget);
    expect(find.textContaining('Confirm by Code'), findsOneWidget);
    expect(find.textContaining("I've Scanned"), findsNothing);
    expect(find.byKey(const Key('posPayQrCard')), findsOneWidget);

    // The right code — derived from the SAME stable order id and total
    // the page shows — verifies with zero server contact.
    final state = container.read(posCartProvider);
    final shopId = (LocalStorage.getShopJson()?['id'])?.toString() ?? '';
    final secret =
        (LocalStorage.getShopJson()?['uuid'])?.toString() ?? shopId;
    final good = PosPayVerification.code(
      orderId: state.orderId,
      amount: state.total,
      shopId: shopId,
      sharedSecret: secret,
    );

    final codeField = find.byType(TextField);
    await tester.enterText(codeField, '000001' == good ? '000002' : '000001');
    await tester.pump();
    expect(find.textContaining("doesn't match"), findsOneWidget);
    expect(find.text('Payment confirmed'), findsNothing);

    await tester.enterText(codeField, good);
    await tester.pump();
    expect(find.text('Payment confirmed'), findsOneWidget);
    expect(find.textContaining("doesn't match"), findsNothing);
  });

  testWidgets(
      'dual finish: "Print Receipt & Finish" is atomic — a dead printer '
      'leaves the sale open; "Finish without Receipt" completes it',
      (tester) async {
    PosConnectivity.debugConnectivityOverride = true;
    final container = await _pumpWithCart(tester);
    expect(container.read(posCartProvider).lines, hasLength(1));

    // A throwing printer: the sale must NOT be recorded (the retired
    // Spazafy checkout recorded first and silently ate the receipt).
    PosReceiptPrinter.handler = (orderId, lines, total) async {
      throw StateError('printer offline');
    };
    await tester.tap(find.text('Print Receipt & Finish'));
    await tester.pumpAndSettle();
    expect(container.read(posCartProvider).lines, hasLength(1),
        reason: 'atomic print+finish: failed print leaves the sale open');

    // A working printer receives the order and THEN the sale records.
    String? printedOrder;
    double? printedTotal;
    int? printedLineCount;
    PosReceiptPrinter.handler = (orderId, lines, total) async {
      printedOrder = orderId;
      printedTotal = total;
      printedLineCount = lines.length;
    };
    final orderId = container.read(posCartProvider).orderId;
    await tester.tap(find.text('Print Receipt & Finish'));
    await tester.pumpAndSettle();
    expect(printedOrder, orderId);
    expect(printedTotal, 150);
    expect(printedLineCount, 1);
    expect(container.read(posCartProvider).lines, isEmpty);
    expect(container.read(posCartProvider).total, 0);

    // Finish without Receipt: no printing, straight to done.
    var printCalls = 0;
    PosReceiptPrinter.handler = (orderId, lines, total) async {
      printCalls++;
    };
    await container.read(posCartProvider.notifier).addByBarcode('600777');
    await tester.pump();
    await tester.tap(find.text('Finish without Receipt'));
    await tester.pumpAndSettle();
    expect(printCalls, 0);
    expect(container.read(posCartProvider).lines, isEmpty);
  });
}
