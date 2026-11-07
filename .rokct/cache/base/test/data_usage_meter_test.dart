// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, version 3.

import 'dart:convert';

import 'package:base_sdk/base_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final meter = DataUsageMeter.instance;
  var clock = DateTime(2026, 11, 6, 10);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    meter.resetForTest();
    clock = DateTime(2026, 11, 6, 10);
    DataUsageMeter.now = () => clock;
    DataUsageMeter.networkOverride = DataNetwork.wifi;
  });

  tearDown(() {
    meter.resetForTest();
    DataUsageMeter.now = DateTime.now;
    DataUsageMeter.networkOverride = null;
  });

  test('splits Wi-Fi and mobile, for today and this month', () {
    meter.record(1000);
    DataUsageMeter.networkOverride = DataNetwork.mobile;
    meter.record(300);
    expect(meter.today, const DataUsageTotals(wifi: 1000, mobile: 300));
    expect(meter.thisMonth.total, 1300);
  });

  test('a new day starts today at zero but keeps the month', () {
    meter.record(1000);
    clock = DateTime(2026, 11, 7, 1);
    meter.record(50);
    expect(meter.today.total, 50);
    expect(meter.thisMonth.total, 1050);
    clock = DateTime(2026, 12, 1, 1);
    expect(meter.thisMonth.total, 0);
    expect(meter.today.total, 0);
  });

  test('totals survive a restart', () async {
    meter.record(2048);
    await meter.save();
    meter.resetForTest();
    expect(meter.today.wifi, 2048);
  });

  test('a metered http client counts what it sends and receives', () async {
    final body = 'x' * 5000;
    final c = MeteredHttpClient(
      MockClient((r) async => http.Response(body, 200)),
    );
    final res = await c.post(
      Uri.parse('https://unit.test/rpc'),
      body: jsonEncode({'a': 1}),
    );
    expect(res.body.length, 5000);
    // Body sizes plus one header allowance each way.
    expect(meter.today.total, 5000 + 7 + 2 * DataUsageMeter.headerAllowance);
  });

  test('sizes read like a phone data screen', () {
    expect(DataUsageMeter.format(800), '1 KB');
    expect(DataUsageMeter.format(4400000), '4.2 MB');
    expect(DataUsageMeter.format(64000000), '61 MB');
    expect(DataUsageMeter.format(1400000000), '1.3 GB');
  });

  testWidgets('the badge shows today and this month, tap shows the split', (
    t,
  ) async {
    meter.record(4400000);
    await meter.save(); // no pending write timer at the end
    await t.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => const MaterialApp(
          home: Scaffold(body: Center(child: DataUsageBadge())),
        ),
      ),
    );
    expect(find.text('4.2 MB used today · 4.2 MB this month'), findsOneWidget);
    await t.tap(find.byType(DataUsageBadge));
    await t.pumpAndSettle();
    expect(find.text('Wi-Fi 4.2 MB'), findsNWidgets(2));
    expect(find.text('Mobile data 0 KB'), findsNWidgets(2));
  });
}
