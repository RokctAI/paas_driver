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

// Source contract for the driver income template's two-column plane on
// medium+ windows (revenue_sdk 1.12.5, landscape branch 1.13.1).
//
// `templates/` is excluded from analysis (analysis_options.yaml), so the
// guard here is textual, like driver_income_template_headers_test.dart -
// it pins the SHAPE of the source. The geometry the shape produces is
// measured for real next door, in driver_income_landscape_test.dart, which
// builds this same file under base's app_widget host recipe at the four
// tablet stills. Between them: at 800x1280 dp the single column was 84 dp
// taller than the reserved-slot viewport and the 300.h chart card
// straddled the fold; with the plane the card sits whole, 12 dp above its
// column's bottom edge, and neither column scrolls; at 432x768 dp (phone)
// the widget tree and every rect are those of 1.12.4.
//
// What it pins:
//
// 1. The switch is base's window-size class (`windowSizeOf(context)
//    .isAtLeastMedium`, AppBreakpoints.medium = 600 dp) - the SAME width
//    at which base's templates/app_widget.dart stops scaling ScreenUtil
//    from the 375x812 design and passes the logical size (1:1). A
//    hand-rolled breakpoint here would drift from it.
// 2. The wide branch is a Row of exactly two Expanded columns: the order
//    prices and the transactions section (wallet, bank accounts,
//    statistics) on the left, the chart on the right, with the segmented
//    control full width above them.
// 3. The compact branch keeps the single column, still ending with
//    `_chart(state)` after the transactions section.
// 4. The statistics tiles size from their row's constraints (a
//    LayoutBuilder), not the window width - the window-width formula
//    overflowed the half-width column by a full tile.
// 5. The left column reflows when it is LANDSCAPE (wider than it is tall,
//    which is the 1280x800 still): the order-price card stands beside the
//    transaction rows and the tiles keep the full width underneath, so
//    nothing has to scroll under the Withdraw bar.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _incomePage = 'templates/pages/driver/income/income_page.dart';
const _statistics = 'templates/pages/driver/income/statistics_screen.dart';
const _statisticsItem =
    'templates/pages/driver/income/widgets/statistics_item.dart';

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

/// The argument list of the first `[marker]` constructor call in [source]
/// at or after [from], found by walking to the matching close paren.
String _call(String source, String marker, {int from = 0}) {
  final start = source.indexOf(marker, from);
  expect(start, isNot(-1), reason: 'no $marker in the template');
  var depth = 0;
  for (var i = start + marker.length - 1; i < source.length; i++) {
    final c = source[i];
    if (c == '(') depth++;
    if (c == ')') {
      depth--;
      if (depth == 0) return source.substring(start + marker.length, i);
    }
  }
  fail('unbalanced $marker call');
}

/// [source] without its `//` comment lines, so a comment that explains the
/// layout by name cannot satisfy or defeat a check on the code.
String _code(String source) => source
    .split('\n')
    .where((line) => !line.trimLeft().startsWith('//'))
    .join('\n');

void main() {
  final incomePage = _code(File(_incomePage).readAsStringSync());
  final statistics = _code(File(_statistics).readAsStringSync());
  final statisticsItem = _code(File(_statisticsItem).readAsStringSync());

  group('driver income switches on base\'s window-size class', () {
    test('income_page.dart imports base\'s breakpoints', () {
      expect(
        incomePage,
        contains(
            "import 'package:base_sdk/src/presentation/adaptive/breakpoints.dart';"),
      );
    });

    test('the one switch is windowSizeOf(context).isAtLeastMedium', () {
      final build = _method(incomePage, 'Widget build(BuildContext context)');
      expect(
        build,
        contains('final isWide = windowSizeOf(context).isAtLeastMedium;'),
        reason: 'the wide branch must switch exactly where base\'s '
            'app_widget.dart switches ScreenUtil to 1:1',
      );
      expect(RegExp(r'\bisWide\b').allMatches(incomePage), hasLength(2),
          reason: 'declared once, read once');
      expect(build, contains('isWide\n'));
      expect(build, contains('? _wideBody(context, state)'));
      expect(build, contains(': SingleChildScrollView('));
      // No second breakpoint of its own.
      expect(incomePage, isNot(contains('MediaQuery.sizeOf')));
      expect(incomePage, isNot(contains('AppBreakpoints.')));
    });
  });

  group('driver income wide branch', () {
    String wideBody() => _method(incomePage, 'Widget _wideBody(');

    test('the segmented control stays full width above the columns', () {
      final wide = wideBody();
      expect(wide.indexOf('CustomTabBar('), lessThan(wide.indexOf('Row(')));
      expect(RegExp(r'CustomTabBar\(').allMatches(incomePage), hasLength(2),
          reason: 'one per branch');
    });

    test('a Row of exactly two Expanded columns', () {
      final row = _call(wideBody(), 'Row(');
      expect(row, contains('crossAxisAlignment: CrossAxisAlignment.start'));
      expect(RegExp(r'Expanded\(').allMatches(row), hasLength(2));
    });

    test('left: order prices and the transactions section; right: the chart',
        () {
      final row = _call(wideBody(), 'Row(');
      final left = _call(row, 'Expanded(');
      final right =
          _call(row, 'Expanded(', from: row.indexOf('Expanded(') + 1);
      expect(left, contains('_orderPrices(context, state)'));
      expect(left, contains('..._transactions(context, state)'));
      expect(left, isNot(contains('_chart(')));
      expect(right, contains('_chart(state)'));
      expect(right, isNot(contains('_transactions(')));
      expect(right, isNot(contains('_orderPrices(')));
      // Each column scrolls on its own.
      expect(left, contains('SingleChildScrollView('));
      expect(right, contains('SingleChildScrollView('));
    });

    test('the transactions section is the shared list', () {
      // One definition of the portrait order, composed from the two
      // halves the landscape branch places separately.
      final section = _method(incomePage, 'List<Widget> _transactions(');
      expect(
        section,
        matches(RegExp(r'\.\.\._transactionRows\(context\),\s*'
            r'24\.verticalSpace,\s*_statistics\(state\),')),
        reason: 'rows, 24, tiles - in that order:\n$section',
      );
      expect(section, isNot(contains('_chart(')));

      final rows = _method(incomePage, 'List<Widget> _transactionRows(');
      expect(rows, contains('TrKeys.deliverymanTransactions'));
      expect(rows, contains('DriverWalletPage.push(context)'));
      expect(rows, contains("Key('incomeBankAccountsRow')"));
      expect(rows, isNot(contains('StatisticsScreen(')));

      final statistics = _method(incomePage, 'Widget _statistics(');
      expect(statistics, contains('StatisticsScreen('));
    });
  });

  group('driver income left column reflows when it is landscape', () {
    test('the branch is the column\'s own box, not a dp threshold', () {
      final wide = _method(incomePage, 'Widget _wideBody(');
      expect(wide, contains('LayoutBuilder('));
      expect(wide, contains('final landscape = box.maxWidth > box.maxHeight;'),
          reason: 'wider than it is tall - no hand-tuned dp number');
      expect(wide, contains('? _landscapeColumn(context, state)'));
      // Portrait keeps the stack it has always had.
      expect(wide, contains('_orderPrices(context, state)'));
      expect(wide, contains('..._transactions(context, state)'));
    });

    test('landscape stands the card beside the rows, tiles full width', () {
      final column = _method(incomePage, 'Widget _landscapeColumn(');
      final row = _call(column, 'Row(');
      expect(row, contains('crossAxisAlignment: CrossAxisAlignment.start'));
      expect(RegExp(r'Expanded\(').allMatches(row), hasLength(2));
      expect(row, contains('_orderPriceCard(context, state)'));
      expect(row, contains('_transactionRows(context)'));
      // The tiles are NOT in the row - they keep the column's full width.
      expect(row, isNot(contains('_statistics(')));
      expect(column, contains('_statistics(state)'));
      expect(column.indexOf('Row('), lessThan(column.indexOf('_statistics(')));
      // Nothing is dropped: the landscape column carries all four pieces.
      expect(column, isNot(contains('_chart(')));
    });

    test('the order-price card is one widget both branches use', () {
      final stacked = _method(incomePage, 'Column _orderPrices(');
      expect(stacked, contains('_orderPriceCard(context, state)'));
      expect(stacked, contains('32.verticalSpace'),
          reason: 'the stacked branch keeps its gap under the card');
      expect(RegExp(r'_orderPriceCard\(context, state\)')
          .allMatches(incomePage), hasLength(2),
          reason: 'declared once, called from each branch');
    });
  });

  group('driver income compact branch is the single column', () {
    test('the scroller\'s column still ends with the chart', () {
      final build = _method(incomePage, 'Widget build(BuildContext context)');
      final compact = build.substring(build.indexOf(': SingleChildScrollView('));
      expect(
        compact,
        matches(RegExp(
            r'CustomTabBar\([\s\S]*?24\.verticalSpace,\s*_orderPrices\(context, state\),\s*\.\.\._transactions\(context, state\),\s*32\.verticalSpace,\s*_chart\(state\),\s*\],')),
        reason: 'tab bar, order prices, transactions, 32, chart - in that '
            'order, in one column:\n$compact',
      );
    });
  });

  group('statistics tiles size from their row, not the window', () {
    test('statistics_screen.dart derives the tile width in a LayoutBuilder',
        () {
      expect(statistics, contains('LayoutBuilder('));
      expect(
        statistics,
        contains('final tileWidth = (constraints.maxWidth - 108.w) / 2;'),
        reason: '(row - 108.w) / 2 is the phone formula (window - 140.w) '
            '/ 2 under the page\'s 16.w side padding',
      );
      expect(statistics, isNot(contains('MediaQuery.sizeOf')));
    });

    test('every tile is handed that width', () {
      final calls = RegExp(r'StatisticsItem\(').allMatches(statistics);
      expect(calls, hasLength(4));
      for (final call in calls) {
        expect(_call(statistics, 'StatisticsItem(', from: call.start),
            contains('width: tileWidth'));
      }
    });

    test('statistics_item.dart takes the width and keeps the fallback', () {
      expect(statisticsItem, contains('final double? width;'));
      expect(statisticsItem, contains('this.width});'));
      expect(
        statisticsItem,
        contains(
            'width: width ?? (MediaQuery.sizeOf(context).width - 140.w) / 2,'),
      );
    });
  });
}
