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

// Source contract for the driver income template's section headers and its
// bottom bar.
//
// `templates/` is excluded from analysis (analysis_options.yaml) and only
// compiles in the HOST package after install, so nothing here can build the
// page; the guard is textual, like driver_income_template_deps_test.dart.
//
// Two regressions it pins, both from paas_driver's landed stills of the
// page (revenue_sdk 1.12.2):
//
// 1. base's `TitleAndIcon` defaults `titleColor` / `rightTitleColor` to the
//    polarity-pinned const `AppStyle.black` (0xFF232B2F). On the page's
//    `AppStyle.surfaceDark` ground that is a 1.30:1 header - "Deliveryman
//    transactions", "Your payouts", "Statistics", "Earnings chart" all
//    vanished. Every `TitleAndIcon` the template builds must pass the
//    mode-resolving `AppStyle.textPrimary` (and the right title likewise
//    where one is set).
// 2. `extendBody: true` let the body run UNDER the Scaffold's bottom slot,
//    whose Withdraw button is OPAQUE, so the last ~100 dp of content (the
//    chart's last bars on the tablet, the statistics tiles on the phone)
//    sat behind it at scroll rest. The Scaffold must reserve the slot.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _incomePage = 'templates/pages/driver/income/income_page.dart';
const _statistics = 'templates/pages/driver/income/statistics_screen.dart';

/// The argument list of every `TitleAndIcon(` constructor call in [source],
/// found by walking to the matching close paren (the calls nest closures
/// and further calls, so a regex would stop short).
List<String> _titleAndIconCalls(String source) {
  const marker = 'TitleAndIcon(';
  final calls = <String>[];
  var from = source.indexOf(marker);
  while (from != -1) {
    var depth = 0;
    var end = -1;
    for (var i = from + marker.length - 1; i < source.length; i++) {
      final c = source[i];
      if (c == '(') depth++;
      if (c == ')') {
        depth--;
        if (depth == 0) {
          end = i;
          break;
        }
      }
    }
    expect(end, isNot(-1), reason: 'unbalanced TitleAndIcon( call');
    calls.add(source.substring(from + marker.length, end));
    from = source.indexOf(marker, end);
  }
  return calls;
}

/// The body of the method whose signature starts with [marker], up to the
/// close of its outermost brace.
String _method(String source, String marker) {
  final from = source.indexOf(marker);
  expect(from, isNot(-1), reason: 'no $marker in the template');
  final open = source.indexOf('{', from);
  var depth = 0;
  for (var i = open; i < source.length; i++) {
    final c = source[i];
    if (c == '{') depth++;
    if (c == '}') {
      depth--;
      if (depth == 0) return source.substring(from, i + 1);
    }
  }
  fail('unbalanced braces after $marker');
}

/// [source] without its `//` comment lines, so a comment that explains the
/// bug by name cannot satisfy or defeat a check on the code.
String _code(String source) => source
    .split('\n')
    .where((line) => !line.trimLeft().startsWith('//'))
    .join('\n');

void main() {
  final incomePage = _code(File(_incomePage).readAsStringSync());
  final statistics = _code(File(_statistics).readAsStringSync());

  group('driver income section headers are mode-resolving', () {
    test('income_page.dart builds the transactions and chart headers', () {
      // The "Deliveryman transactions" / "Your payouts" row and the
      // "Earnings chart" header.
      expect(_titleAndIconCalls(incomePage), hasLength(2));
    });

    test('statistics_screen.dart builds the statistics header', () {
      expect(_titleAndIconCalls(statistics), hasLength(1));
    });

    for (final entry in {_incomePage: incomePage, _statistics: statistics}
        .entries) {
      test('every TitleAndIcon in ${entry.key} passes textPrimary', () {
        for (final call in _titleAndIconCalls(entry.value)) {
          expect(
            call,
            contains('titleColor: AppStyle.textPrimary'),
            reason: 'TitleAndIcon in ${entry.key} inherits base\'s const '
                'AppStyle.black default and is unreadable on surfaceDark:\n'
                'TitleAndIcon($call)',
          );
          if (call.contains('rightTitle:')) {
            expect(
              call,
              contains('rightTitleColor: AppStyle.textPrimary'),
              reason: 'the right title in ${entry.key} inherits base\'s '
                  'const AppStyle.black default:\nTitleAndIcon($call)',
            );
          }
        }
      });
    }
  });

  group('driver income withdraw bar does not cover the body', () {
    test('income_page.dart does not extend the body under the bottom slot',
        () {
      expect(
        incomePage,
        isNot(contains('extendBody: true')),
        reason: 'the Scaffold must reserve the bottom slot: the Withdraw '
            'button there is opaque, so a body that runs under it loses '
            'its last rows at scroll rest',
      );
    });

    test('income_page.dart still rides the withdraw bar in the bottom slot',
        () {
      expect(incomePage, contains('bottomNavigationBar: Column('));
      expect(incomePage, contains('TrKeys.withdrawMoney'));
    });

    test('the chart column carries no trailing spacer of its own', () {
      // The scroller's bottom padding is the gap to the bar; a spacer
      // after the chart card stacks on it (44 dp at scroll end against
      // the frames' 12) and scrolls the page past its content.
      final chart = _method(incomePage, 'Column _chart(');
      expect(chart, contains('BarChart('));
      final afterChart = chart.substring(chart.indexOf('BarChart('));
      expect(
        afterChart,
        isNot(contains('verticalSpace')),
        reason: 'no spacer after the chart card:\n$afterChart',
      );
    });
  });

  group('driver income last-income line', () {
    test('the value span leads with a space', () {
      // "Last income" is the translation; the value span must carry the
      // separator or the row reads "Last incomeR45.00".
      final label = incomePage.indexOf('TrKeys.lastIncome');
      expect(label, isNot(-1));
      final value = incomePage.indexOf('lastOrderIncome', label);
      expect(value, isNot(-1));
      final span = incomePage.substring(label, value);
      expect(
        span,
        matches(RegExp(r"text:\s*' \$\{AppHelpers\.numberFormat\(")),
        reason: 'the numberFormat span after the last-income label must '
            'start with a space:\n$span',
      );
    });
  });
}
