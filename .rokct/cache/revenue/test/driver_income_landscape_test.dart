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

// The driver income page's geometry on the four tablet stills the guided
// tour captures, MEASURED - the page is built here, not grepped.
//
// The template only ever compiled inside a composed host, because its three
// sibling imports named `package:${package}/presentation/pages/income/...`.
// They are relative now (the installer copies the whole directory into the
// host's lib/presentation/pages/income, so they resolve there exactly as
// before), which lets this test import the REAL template file and pump it.
// The textual guards next door (driver_income_template_columns_test.dart
// and friends) still pin the source shape; this one pins what it measures.
//
// The host is base's own recipe from core/base/dart/templates/app_widget.dart:
// ScreenUtil with the 375x812 phone design below AppBreakpoints.medium and
// the logical size (1:1) at or above it, inside a Material 2 MaterialApp
// (`useMaterial3: false`) in dark mode - what the composed driver app runs.
//
// What it is for: Ray's ruling that the tablet tour captures LANDSCAPE. At
// 1280x800 the left column's content ran 603 dp against a 474 dp viewport,
// so the still showed the Statistics tiles sliced in half by the Withdraw
// bar. The landscape branch of `_wideBody` stands the order-price card
// beside the transaction rows; the four assertions below are that the left
// column has nothing to scroll and that its last card clears the bar, at
// every geometry - the two landscape ones and the two portrait ones that
// must not regress.

import 'dart:io';

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/models/data/currency_data.dart';
import 'package:base_sdk/src/models/data/profile_data.dart';
import 'package:base_sdk/src/presentation/adaptive/breakpoints.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/title_icon.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:revenue_sdk/src/common/domain/interface/courier_statistics.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/courier_statistics_income_response.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/courier_statistics_order_response.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/courier_statistics_response.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../templates/pages/driver/income/income_page.dart';
import '../templates/pages/driver/income/statistics_screen.dart';

/// The statistics the page draws, fixed so every geometry measures the same
/// content. The numbers are the demo driver's (the tour's account).
class _StubStatistics implements CourierStatisticsRepositoryFacade {
  @override
  Future<ApiResult<CourierStatisticsResponse>> getCourierStatistics() =>
      throw UnimplementedError();

  @override
  Future<ApiResult<CourierStatisticsOrderResponse>> getStatisticsOrder(
          {DateTime? startTime, DateTime? endTime, int? page}) =>
      throw UnimplementedError();

  @override
  Future<ApiResult<CourierStatisticsIncomeResponse>> getStatistics(
          {required DateTime startTime, required DateTime endTime}) async =>
      ApiResult.success(
        data: CourierStatisticsIncomeResponse.fromJson({
          'data': {
            'last_order_total_price': 180,
            'last_order_income': 45,
            'total_count': 133,
            'total_new_count': 1,
            'total_accepted_count': 2,
            'total_canceled_count': 3,
            'total_delivered_count': 128,
            'total_today_count': 6,
            'chart': [
              for (var d = 1; d <= 8; d++)
                {
                  'time': '2026-09-0${d}T10:00:00',
                  'total_price': 400.0 + d * 25,
                },
            ],
          },
        }),
      );
}

/// Roboto, loaded under the family names google_fonts gives Inter, so text
/// MEASURES like a real face.
///
/// Without this the test binding draws Ahem, whose square glyphs are half
/// again as wide as any real font - every header wraps a line early and the
/// numbers below would describe a page nobody ever sees. Roboto ships with
/// the Flutter SDK itself (the `material_fonts` artifact, downloaded on the
/// first `flutter` command), so it is present wherever `flutter test` runs;
/// it is a STAND-IN for Inter, close but not identical in metrics, which is
/// why the assertions below are inequalities and not golden rects.
Future<void> _useRobotoForInter() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null || root.isEmpty) {
    fail('FLUTTER_ROOT is unset; `flutter test` always sets it and the '
        'measurement needs the SDK\'s Roboto to stand in for Inter');
  }
  final fonts = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!fonts.existsSync()) {
    fail('${fonts.path} is missing; run `flutter precache` so the '
        'material_fonts artifact is available to measure text with');
  }
  Future<void> load(String family, String file) async {
    final bytes = File('${fonts.path}/$file').readAsBytesSync();
    await (FontLoader(family)
          ..addFont(Future.value(ByteData.view(bytes.buffer))))
        .load();
  }

  // AppStyle.inter* reach for regular / 500 / 600 / 700.
  await load('Inter_regular', 'Roboto-Regular.ttf');
  await load('Inter_500', 'Roboto-Medium.ttf');
  await load('Inter_600', 'Roboto-Bold.ttf');
  await load('Inter_700', 'Roboto-Bold.ttf');
}

/// base's app_widget recipe: ScreenUtil off the phone design only on a
/// compact window, the Material 2 theme pair, dark mode.
Widget _host(Size logical) => ProviderScope(
      child: ScreenUtilInit(
        useInheritedMediaQuery: false,
        designSize: logical.width < AppBreakpoints.medium
            ? const Size(375, 812)
            : logical,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: false,
            brightness: Brightness.light,
            scaffoldBackgroundColor: AppStyle.surfaceLightRaw,
          ),
          darkTheme: ThemeData(
            useMaterial3: false,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppStyle.surfaceDarkRaw,
          ),
          themeMode: ThemeMode.dark,
          home: const IncomePage(),
        ),
      ),
    );

/// One still: what the left column had to scroll, and where its last card
/// ended relative to the Withdraw bar.
class _Still {
  _Still({
    required this.leftExtent,
    required this.rightExtent,
    required this.leftViewport,
    required this.statisticsBottom,
    required this.buttonTop,
    required this.orderCard,
    required this.transactionsHeader,
    required this.scrollers,
  });

  final double leftExtent;
  final double rightExtent;
  final double leftViewport;
  final double statisticsBottom;
  final double buttonTop;
  final Rect orderCard;
  final Rect transactionsHeader;
  final int scrollers;

  /// The order-price card and the transactions header stand SIDE BY SIDE
  /// (the landscape arrangement) rather than stacked: the card ends before
  /// the header begins, and the two overlap on the vertical, so they are
  /// beside each other and not merely indented.
  bool get sideBySide =>
      orderCard.right <= transactionsHeader.left &&
      orderCard.top < transactionsHeader.bottom &&
      transactionsHeader.top < orderCard.bottom;

  @override
  String toString() => 'left maxScrollExtent=$leftExtent '
      '(viewport $leftViewport), right=$rightExtent, '
      'statistics bottom=$statisticsBottom, Withdraw top=$buttonTop';
}

Future<_Still> _still(WidgetTester tester,
    {required Size physical, required double dpr}) async {
  tester.view.physicalSize = physical;
  tester.view.devicePixelRatio = dpr;
  // The tour's device: a status bar, and a gesture-navigation window with
  // no bottom inset.
  tester.view.padding = FakeViewPadding(top: 24 * dpr);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_host(physical / dpr));
  await tester.pumpAndSettle(const Duration(milliseconds: 200));

  final scrollers = find
      .byType(Scrollable)
      .evaluate()
      .map((e) => ((e as StatefulElement).state as ScrollableState).position)
      .where((p) => p.axis == Axis.vertical)
      .toList();
  ScrollPosition columnAt(Key key) {
    final scrollable = find
        .descendant(of: find.byKey(key), matching: find.byType(Scrollable))
        .evaluate()
        .single as StatefulElement;
    return (scrollable.state as ScrollableState).position;
  }

  final left = columnAt(const Key('incomeWideLeftColumn'));
  final right = columnAt(const Key('incomeWideRightColumn'));
  final header = find
      .byWidgetPredicate((w) => w is TitleAndIcon && w.rightTitle == 'Your payouts')
      .first;

  return _Still(
    leftExtent: left.maxScrollExtent,
    rightExtent: right.maxScrollExtent,
    leftViewport: left.viewportDimension,
    statisticsBottom: tester.getRect(find.byType(StatisticsScreen)).bottom,
    buttonTop: tester.getRect(find.byType(CustomButton)).top,
    orderCard: tester.getRect(find.text('Order price')),
    transactionsHeader: tester.getRect(header),
    scrollers: scrollers.length,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    await LocalStorage.setSelectedCurrency(CurrencyData.fromJson(
        {'id': 'ZAR', 'symbol': 'R', 'title': 'Rand', 'position': 'before'}));
    await LocalStorage.setUser(ProfileData.fromJson({
      'id': 1,
      'wallet': {'id': 1, 'price': 793},
    }));
    if (!GetIt.instance.isRegistered<CourierStatisticsRepositoryFacade>()) {
      GetIt.instance.registerSingleton<CourierStatisticsRepositoryFacade>(
          _StubStatistics());
    }
    await _useRobotoForInter();
  });

  // The four stills the guided tour takes of this page. Both landscape
  // geometries and both portrait ones are the SAME physical panel at two
  // densities (320 dpi -> dpr 2.0, 240 dpi -> dpr 1.5).
  const stills = [
    ('landscape 1280x800 dp', Size(2560, 1600), 2.0, true),
    ('landscape 1706x1066 dp', Size(2560, 1600), 1.5, true),
    ('portrait 800x1280 dp', Size(1600, 2560), 2.0, false),
    ('portrait 1066x1706 dp', Size(1600, 2560), 1.5, false),
  ];

  for (final still in stills) {
    final (label, physical, dpr, landscape) = still;

    testWidgets('$label: the left column has nothing to scroll',
        (tester) async {
      final s = await _still(tester, physical: physical, dpr: dpr);
      expect(s.scrollers, 2, reason: 'the wide plane is two columns: $s');
      expect(
        s.leftExtent,
        0.0,
        reason: 'the left column must fit its viewport - anything it has to '
            'scroll is a card the still cuts in half: $s',
      );
      expect(s.rightExtent, 0.0, reason: 'the chart column too: $s');
    });

    testWidgets('$label: the statistics tiles clear the Withdraw bar',
        (tester) async {
      final s = await _still(tester, physical: physical, dpr: dpr);
      expect(
        s.statisticsBottom,
        lessThanOrEqualTo(s.buttonTop),
        reason: 'the tiles end above the bar, whole: $s',
      );
    });

    testWidgets(
        '$label: the order-price card is '
        '${landscape ? 'beside' : 'above'} the transaction rows',
        (tester) async {
      final s = await _still(tester, physical: physical, dpr: dpr);
      if (landscape) {
        expect(s.sideBySide, isTrue,
            reason: 'a short, wide column stands them side by side: '
                'card=${s.orderCard}, header=${s.transactionsHeader}');
      } else {
        expect(s.sideBySide, isFalse);
        expect(
          s.orderCard.bottom,
          lessThanOrEqualTo(s.transactionsHeader.top),
          reason: 'portrait keeps the approved stack: '
              'card=${s.orderCard}, header=${s.transactionsHeader}',
        );
      }
    });
  }

  testWidgets('a phone window still gets the single column', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.5;
    tester.view.padding = const FakeViewPadding(top: 60);
    addTearDown(tester.view.reset);
    final overflows = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception.toString().contains('overflowed')) {
        overflows.add(details.exception.toString().split('\n').first);
        return;
      }
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);

    await tester.pumpWidget(_host(const Size(432, 768)));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(find.byKey(const Key('incomeWideLeftColumn')), findsNothing);
    expect(find.byKey(const Key('incomeWideRightColumn')), findsNothing);
    expect(find.byType(Scrollable), findsOneWidget);
    // The compact page is taller than any phone and scrolls, exactly as it
    // did before the wide plane existed.
    final position =
        (find.byType(Scrollable).evaluate().single as StatefulElement).state
            as ScrollableState;
    expect(position.position.maxScrollExtent, greaterThan(0));
    expect(
      tester.getRect(find.text('Order price')).bottom,
      lessThanOrEqualTo(tester
          .getRect(find
              .byWidgetPredicate(
                  (w) => w is TitleAndIcon && w.rightTitle == 'Your payouts')
              .first)
          .top),
      reason: 'the phone keeps the stack',
    );
  });
}
