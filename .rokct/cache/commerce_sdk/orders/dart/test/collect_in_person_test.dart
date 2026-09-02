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
// Delivery collected in person (approved design strip section 43): the
// customer turns up at the counter for an order she placed for delivery.
// The goods are never withheld; what these tests hold to is that the
// surface never lies about where the delivery fee ends up, and that the
// conversion is ONE call.

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';
import 'package:orders_sdk/src/manager/presentation/board/board_card.dart';
import 'package:orders_sdk/src/manager/presentation/board/board_status.dart';
import 'package:orders_sdk/src/manager/presentation/collect/collect_confirm_sheet.dart';
import 'package:orders_sdk/src/manager/presentation/collect/collect_in_person_panel.dart';
import 'package:orders_sdk/src/manager/presentation/collect/collect_in_person_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records every conversion call so "ONE call, never a sequence" is
/// something the tests can actually check.
class _FakeSellerOrders extends Fake implements SellerOrdersRepositoryFacade {
  final List<String> calls = [];
  CollectConversion result = const CollectConversion(
    converted: true,
    driverWasAssigned: false,
    feeOutcome: CollectFeeOutcome.refunded,
    refundedToWallet: 35,
  );
  String? failure;

  @override
  Future<ApiResult<CollectConversion>> convertDeliveryToCollected({
    required String orderId,
  }) async {
    calls.add(orderId);
    if (failure != null) {
      return ApiResult.failure(error: failure!, statusCode: 400);
    }
    return ApiResult.success(data: result);
  }
}

OrderData _order({
  String id = '2417',
  String type = 'delivery',
  Object? deliveryman,
  String? deliverymanName,
  num fee = 35,
  num total = 248,
  bool collected = false,
  num refunded = 0,
}) => OrderData(
  id: id,
  deliveryType: type,
  deliveryFee: fee,
  totalPrice: total,
  deliveryman: deliveryman,
  deliverymanName: deliverymanName,
  collectedInPerson: collected,
  collectFeeRefunded: refunded,
  createdAt: '2026-08-30T14:31:00',
  updatedAt: '2026-08-30T14:31:00',
  user: UserData(firstname: 'Naledi', lastname: 'Mokoena'),
);

Widget _host(Widget child, {double width = 1280}) => ProviderScope(
  child: ScreenUtilInit(
    designSize: Size(width, 900),
    builder: (_, __) => MaterialApp(
      home: Scaffold(
        backgroundColor: AppStyle.surfaceDark,
        body: SingleChildScrollView(child: child),
      ),
    ),
  ),
);

/// Everything the surface actually says, Text and RichText alike —
/// several of these strings are built as spans so the amount and the
/// destination can carry the branch colour.
String said(WidgetTester tester) => [
  ...tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? ''),
  ...tester
      .widgetList<RichText>(find.byType(RichText))
      .map((r) => r.text.toPlainText()),
].join(' | ');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakeSellerOrders repo;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  setUp(() {
    repo = _FakeSellerOrders();
    final getIt = GetIt.instance;
    if (getIt.isRegistered<SellerOrdersRepositoryFacade>()) {
      getIt.unregister<SellerOrdersRepositoryFacade>();
    }
    getIt.registerSingleton<SellerOrdersRepositoryFacade>(repo);
  });

  group('the envelope', () {
    test('reads the endpoint response, wrapped or bare', () {
      const body = {
        'converted': true,
        'already_converted': false,
        'driver_was_assigned': true,
        'unassigned_deliveryman': 'thabo@example.com',
        'delivery_type': 'pickup',
        'delivery_fee': 35,
        'fee_outcome': 'kept',
        'refunded_to_wallet': 0,
        'total_price': 248,
        'total_price_before': 248,
      };
      for (final json in [body, {'message': body}]) {
        final parsed = CollectConversion.fromJson(json);
        expect(parsed.converted, isTrue);
        expect(parsed.driverWasAssigned, isTrue);
        expect(parsed.feeOutcome, CollectFeeOutcome.kept);
        expect(parsed.refundedToWallet, 0);
        expect(parsed.totalPriceBefore, 248);
        expect(parsed.deferred, isFalse);
      }
    });

    test('an unknown fee outcome promises nothing', () {
      expect(
        CollectConversion.fromJson(const {'fee_outcome': 'whatever'})
            .feeOutcome,
        CollectFeeOutcome.none,
      );
      expect(const CollectConversion.deferred().deferred, isTrue);
      expect(
        const CollectConversion.deferred().feeOutcome,
        CollectFeeOutcome.none,
      );
    });
  });

  group('811 / 812 — the row that decides the branch', () {
    testWidgets('empty: nobody has been dispatched', (tester) async {
      await tester.pumpWidget(_host(const CollectDriverRow()));
      await tester.pump();
      expect(find.text('No driver assigned yet'), findsOneWidget);
      expect(
        find.text('Nobody has been dispatched for this order'),
        findsOneWidget,
      );
      expect(find.text('ON A CALLOUT'), findsNothing);
    });

    testWidgets('assigned: the driver, and that he is on a callout',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const CollectDriverRow(
            driverName: 'Thabo Dlamini',
            assignedAtLabel: 'Assigned · picked up 6m',
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Thabo Dlamini'), findsOneWidget);
      expect(find.text('Assigned · picked up 6m'), findsOneWidget);
      expect(find.text('ON A CALLOUT'), findsOneWidget);
    });
  });

  group('814 / 815 — the outcome, before the tap', () {
    Future<String> copy(WidgetTester tester, Widget widget) async {
      await tester.pumpWidget(_host(widget));
      await tester.pump();
      return said(tester);
    }

    testWidgets('no driver: the fee goes back, and it says where',
        (tester) async {
      final text = await copy(
        tester,
        const CollectOutcomeLine(driverAssigned: false, feeText: 'R35.00'),
      );
      expect(text, contains('No driver was on it yet so the'));
      expect(text, contains('R35.00'));
      expect(text, contains('goes back to the customers wallet'));
      expect(text, isNot(contains('kept')));
    });

    testWidgets('driver assigned: the fee is kept, and it says why',
        (tester) async {
      final text = await copy(
        tester,
        const CollectOutcomeLine(
          driverAssigned: true,
          driverName: 'Thabo Dlamini',
          feeText: 'R35.00',
        ),
      );
      expect(text, contains('Thabo Dlamini'));
      expect(text, contains('R35.00'));
      expect(text, contains('Fee is kept'));
      expect(text, contains('It covers the callout and his task cancels'));
      expect(text, isNot(contains('goes back')));
    });

    testWidgets('offline: it promises nothing about the money',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const CollectOutcomeLine(driverAssigned: null, feeText: 'R35.00'),
        ),
      );
      await tester.pump();
      expect(said(tester), contains('live on the server'));
      expect(said(tester), isNot(contains('R35.00')));
    });
  });

  group('816 — the till line', () {
    testWidgets('stands alone until the order in hand resolves it',
        (tester) async {
      await tester.pumpWidget(_host(const CollectTillLine()));
      await tester.pump();
      expect(
        find.text('Fee comes back if no driver was on it yet'),
        findsOneWidget,
      );
    });

    testWidgets('gains its resolving clause when a driver was on it',
        (tester) async {
      await tester.pumpWidget(
        _host(const CollectTillLine(driverAssigned: true)),
      );
      await tester.pump();
      expect(said(tester), contains('This one had a driver on it so it does not'));
    });
  });

  group('813 — the action lane', () {
    testWidgets('online it names the conversion; offline it is relabelled '
        'IN PLACE and stays enabled', (tester) async {
      await tester.pumpWidget(
        _host(CollectActionLane(onPressed: () {}, offline: false)),
      );
      await tester.pump();
      expect(find.text('Customer is here convert to pickup'), findsOneWidget);

      await tester.pumpWidget(
        _host(CollectActionLane(onPressed: () {}, offline: true)),
      );
      await tester.pump();
      expect(
        find.text('Hand over now convert when back online'),
        findsOneWidget,
      );
      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(button.onPressed, isNotNull);
    });
  });

  group('817 / 818 / 819 — the confirm guard', () {
    Future<void> pumpSheet(WidgetTester tester, {required bool assigned}) =>
        tester.pumpWidget(
          _host(
            CollectConfirmSheet(
              customerName: 'Naledi Mokoena',
              orderId: '2417',
              totalText: 'R248.00',
              feeText: 'R35.00',
              driverAssigned: assigned,
              driverName: assigned ? 'Thabo Dlamini' : null,
              onConfirm: () {},
            ),
          ),
        );

    testWidgets('four rows, one per thing that actually moves',
        (tester) async {
      await pumpSheet(tester, assigned: true);
      await tester.pump();
      expect(find.byType(CollectLedgerRow), findsNWidgets(4));
      expect(find.text('Goods'), findsOneWidget);
      expect(find.text('Driver task'), findsOneWidget);
      expect(said(tester), contains('Handed to the customer now'));
      expect(said(tester), contains('Delivery → Pickup'));
    });

    testWidgets('the two branches differ in rows 3 and 4, and nowhere else',
        (tester) async {
      await pumpSheet(tester, assigned: true);
      await tester.pump();
      expect(said(tester), contains('Kept not refunded'));
      expect(
        said(tester),
        contains('Is unassigned and his task cancels in the driver app'),
      );

      await pumpSheet(tester, assigned: false);
      await tester.pump();
      expect(said(tester), contains('Refunded to the customers wallet'));
      expect(said(tester), contains('Nobody to stand down'));
      expect(said(tester), isNot(contains('Kept not refunded')));
    });

    testWidgets('the affirmative button is the wider one', (tester) async {
      await pumpSheet(tester, assigned: true);
      await tester.pump();
      final cancel = tester.getSize(
        find.ancestor(
          of: find.byType(OutlinedButton),
          matching: find.byType(SizedBox),
        ).first,
      );
      final convert = tester.getSize(
        find.ancestor(
          of: find.byType(ElevatedButton),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(convert.width, greaterThan(cancel.width));
    });
  });

  group('the section', () {
    Future<void> pumpSection(
      WidgetTester tester,
      OrderData order, {
      bool online = true,
      VoidCallback? onConverted,
    }) async {
      await tester.pumpWidget(
        _host(
          CollectInPersonSection(
            order: order,
            onConverted: onConverted,
            connectivity: () async => online,
            clock: () => DateTime.parse('2026-08-30T14:37:00'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('a pickup order has nothing to convert', (tester) async {
      await pumpSection(tester, _order(type: 'pickup'));
      expect(find.byType(CollectActionLane), findsNothing);
    });

    testWidgets('an order already collected in person is spent',
        (tester) async {
      await pumpSection(tester, _order(collected: true));
      expect(find.byType(CollectActionLane), findsNothing);
    });

    testWidgets('a delivery order shows the lane, the row and the outcome',
        (tester) async {
      await pumpSection(tester, _order());
      expect(find.byType(CollectActionLane), findsOneWidget);
      expect(find.byType(CollectDriverRow), findsOneWidget);
      expect(find.byType(CollectOutcomeLine), findsOneWidget);
      expect(find.byType(CollectTillLine), findsOneWidget);
    });

    testWidgets('the driver row carries how long he has had it',
        (tester) async {
      await pumpSection(
        tester,
        _order(
          deliveryman: 'thabo@example.com',
          deliverymanName: 'Thabo Dlamini',
        ),
      );
      expect(said(tester), contains('6m'));
    });

    testWidgets('offline the lane is relabelled and the outcome promises '
        'nothing', (tester) async {
      await pumpSection(tester, _order(), online: false);
      expect(
        find.text('Hand over now convert when back online'),
        findsOneWidget,
      );
      expect(said(tester), contains('live on the server'));
    });

    testWidgets('the confirm guard runs before any conversion',
        (tester) async {
      await pumpSection(tester, _order());
      await tester.tap(find.byType(CollectActionLane));
      await tester.pumpAndSettle();
      expect(find.byType(CollectConfirmSheet), findsOneWidget);
      expect(repo.calls, isEmpty, reason: 'nothing moves before the tap');
    });

    testWidgets('cancelling the guard converts nothing', (tester) async {
      await pumpSection(tester, _order());
      await tester.tap(find.byType(CollectActionLane));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();
      expect(repo.calls, isEmpty);
      expect(find.byType(CollectActionLane), findsOneWidget);
    });

    testWidgets('confirming makes exactly ONE call and spends the lane',
        (tester) async {
      bool converted = false;
      await pumpSection(tester, _order(), onConverted: () => converted = true);
      await tester.tap(find.byType(CollectActionLane));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ElevatedButton).last);
      await tester.pumpAndSettle();

      expect(repo.calls, ['2417']);
      expect(converted, isTrue);
      expect(find.byType(CollectActionLane), findsNothing);
      expect(said(tester), contains('Fee refunded to wallet'));
    });

    testWidgets('offline it converts without a guard and says it is queued',
        (tester) async {
      repo.result = const CollectConversion.deferred();
      await pumpSection(tester, _order(), online: false);
      await tester.tap(find.byType(CollectActionLane));
      await tester.pumpAndSettle();

      expect(find.byType(CollectConfirmSheet), findsNothing);
      expect(repo.calls, ['2417']);
      expect(said(tester), contains('Conversion queued for sync'));
    });

    testWidgets('a refusal is surfaced and the lane survives it',
        (tester) async {
      repo.failure = 'Order is already delivered.';
      await pumpSection(tester, _order());
      await tester.tap(find.byType(CollectActionLane));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ElevatedButton).last);
      await tester.pumpAndSettle();

      expect(find.text('Order is already delivered.'), findsOneWidget);
      expect(find.byType(CollectActionLane), findsOneWidget);
    });
  });

  group('820 / 821 — the converted card states', () {
    Future<void> pumpCard(WidgetTester tester, OrderData order) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 260,
            child: BoardOrderCard(order: order, status: BoardStatus.delivered),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('before: a live fee, no note', (tester) async {
      await pumpCard(tester, _order());
      final text = said(tester);
      expect(text, isNot(contains('Fee refunded')));
      expect(text, isNot(contains('Fee kept')));
      expect(text, contains('Delivery fee'));
    });

    testWidgets('820 fee refunded: the old total is struck and the note is '
        'green', (tester) async {
      await pumpCard(
        tester,
        _order(type: 'pickup', fee: 0, total: 213, collected: true,
            refunded: 35),
      );
      final struck = tester
          .widgetList<RichText>(find.byType(RichText))
          .expand((r) {
            final spans = <InlineSpan>[];
            r.text.visitChildren((s) {
              spans.add(s);
              return true;
            });
            return spans;
          })
          .whereType<TextSpan>()
          .where(
            (s) => s.style?.decoration == TextDecoration.lineThrough,
          )
          .map((s) => s.text)
          .toList();
      expect(struck, isNotEmpty, reason: 'the returned fee must be struck');
      expect(said(tester), contains('Fee refunded to wallet'));
    });

    testWidgets('821 fee kept: nothing is struck and the note is amber',
        (tester) async {
      await pumpCard(
        tester,
        _order(type: 'pickup', fee: 35, total: 248, collected: true),
      );
      final struck = tester
          .widgetList<RichText>(find.byType(RichText))
          .expand((r) {
            final spans = <InlineSpan>[];
            r.text.visitChildren((s) {
              spans.add(s);
              return true;
            });
            return spans;
          })
          .whereType<TextSpan>()
          .where(
            (s) => s.style?.decoration == TextDecoration.lineThrough,
          )
          .toList();
      expect(struck, isEmpty, reason: 'a kept fee is never struck');
      expect(said(tester), contains('Fee kept covers the drivers callout'));
    });
  });
}
