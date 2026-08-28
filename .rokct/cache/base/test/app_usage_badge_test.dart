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

// The profile footer's AppUsageBadge shows exactly ONE usage period,
// chosen app-wide by the home SDK through the AppUsageBadge.period seam
// (last-wins static, same contract shape as AppStyle.injectBrandColors).
// The default — nothing set — is the calendar-year figure, so apps whose
// home SDK does not choose keep the historical rendering.
//
// Small counts render adaptively: the telemetry lane records one
// `app_open` per day and no durations, so hours cannot be derived — 0
// reads the sub-day copy ("Less than a day in app this year"), 1 the
// singular ("1 day in app this year"), and from 2 the counted plural
// with a lower-cased mid-sentence fragment ("45 days in app this year",
// never "45 Days ..." or the old raw "45 DaysInAppThisYear" fallback).
//
// The meta row's version line is the short "v1.2.3" form (the
// spelled-out "App Version" label was retired as too long).

import 'package:base_sdk/base_sdk.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// HttpService whose Dio never touches the network: every request resolves
/// through [respond] — the same stubbing shape as app_usage_service_test.
class _StubHttpService extends HttpService {
  _StubHttpService(this.respond);

  final dynamic Function(RequestOptions options) respond;

  @override
  Dio client({bool requireAuth = false, bool routing = false}) {
    final dio = Dio(BaseOptions(baseUrl: 'https://unit.test'));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: respond(options),
          ),
          true,
        );
      },
    ));
    return dio;
  }
}

/// Points the badge's stats read at a stub gateway serving [week]/[year]
/// day counts for the signed-in test user.
Future<void> _serveStats({required int week, required int year}) async {
  SharedPreferences.setMockInitialValues(
      {StorageKeys.keyToken: 'unit-test-token'});
  await LocalStorage.init();
  GetIt.instance.registerSingleton<HttpService>(
    _StubHttpService((options) => {
          'status': 'success',
          'data': {
            'days_in_app_this_week': week,
            'days_in_app_this_year': year,
          },
        }),
  );
}

Widget _host(Widget child) {
  // ScreenUtilInit mirrors the real app root — the badge's paddings and
  // font sizes are ScreenUtil units. The design size matches the test
  // surface for a 1:1 scale, same as radio's profile page test.
  return ScreenUtilInit(
    designSize: const Size(800, 600),
    builder: (context, _) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    // The seam and the DI slot are app-global; never let one test leak.
    AppUsageBadge.period = AppUsagePeriod.year;
    final getIt = GetIt.instance;
    if (getIt.isRegistered<HttpService>()) {
      getIt.unregister<HttpService>();
    }
  });

  group('AppUsageBadge period seam', () {
    testWidgets('default (no home-SDK choice) renders the year figure only',
        (tester) async {
      await _serveStats(week: 3, year: 45);
      await tester.pumpWidget(_host(const AppUsageBadge()));
      await tester.pumpAndSettle();

      expect(find.textContaining('45 days in app this year'), findsOneWidget);
      expect(find.textContaining('week'), findsNothing);
    });

    testWidgets('home SDK choosing week renders the week figure only',
        (tester) async {
      await _serveStats(week: 3, year: 45);
      AppUsageBadge.period = AppUsagePeriod.week;

      await tester.pumpWidget(_host(const AppUsageBadge()));
      await tester.pumpAndSettle();

      expect(find.textContaining('3 days in app this week'), findsOneWidget);
      expect(find.textContaining('year'), findsNothing);
    });

    testWidgets('explicit choice of year still renders year', (tester) async {
      await _serveStats(week: 3, year: 45);
      AppUsageBadge.period = AppUsagePeriod.year;

      await tester.pumpWidget(_host(const AppUsageBadge()));
      await tester.pumpAndSettle();

      expect(find.textContaining('45 days in app this year'), findsOneWidget);
      expect(find.textContaining('week'), findsNothing);
    });

    testWidgets('per-instance overrides beat the seam (both figures pinned on)',
        (tester) async {
      await _serveStats(week: 3, year: 45);
      AppUsageBadge.period = AppUsagePeriod.year;

      await tester.pumpWidget(_host(
        const AppUsageBadge(showThisWeek: true, showThisYear: true),
      ));
      await tester.pumpAndSettle();

      // One label Text carrying both segments, dot-separated.
      expect(find.textContaining('3 days in app this week'), findsOneWidget);
      expect(find.textContaining('45 days in app this year'), findsOneWidget);
      expect(find.textContaining(' · '), findsOneWidget);
    });
  });

  group('AppUsageBadge small counts', () {
    testWidgets('0 recorded days renders the sub-day copy, not "0 days"',
        (tester) async {
      await _serveStats(week: 0, year: 0);
      await tester.pumpWidget(_host(const AppUsageBadge()));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Less than a day in app this year'),
        findsOneWidget,
      );
      expect(find.textContaining('0'), findsNothing);
    });

    testWidgets('exactly 1 recorded day renders the singular row',
        (tester) async {
      await _serveStats(week: 1, year: 1);
      AppUsageBadge.period = AppUsagePeriod.week;

      await tester.pumpWidget(_host(const AppUsageBadge()));
      await tester.pumpAndSettle();

      expect(find.textContaining('1 day in app this week'), findsOneWidget);
      expect(find.textContaining('days'), findsNothing);
    });

    testWidgets(
        'plural fragment is lower-cased mid-sentence (the week key\'s '
        'humanized fallback starts with a capital)', (tester) async {
      await _serveStats(week: 2, year: 45);
      AppUsageBadge.period = AppUsagePeriod.week;

      await tester.pumpWidget(_host(const AppUsageBadge()));
      await tester.pumpAndSettle();

      expect(find.textContaining('2 days in app this week'), findsOneWidget);
      expect(find.textContaining('Days'), findsNothing);
    });
  });

  group('ProfileMetaRow version line', () {
    testWidgets('shows the short v-prefixed version, not "App Version"',
        (tester) async {
      PackageInfo.setMockInitialValues(
        appName: 'TestApp',
        packageName: 'test.app',
        version: '9.9.9',
        buildNumber: '77',
        buildSignature: '',
        installerStore: null,
      );

      await tester.pumpWidget(_host(const ProfileMetaRow()));
      await tester.pumpAndSettle();

      // Tests run in debug mode, so the build number rides along.
      expect(find.textContaining('v9.9.9+77'), findsOneWidget);
      expect(find.textContaining('App Version'), findsNothing);
    });
  });
}
