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

// The driver order card's LAYOUT CONTRACT on planes, pinned after the
// guided tour died on it (paas_driver run 34166841914, tablet first
// attempt, 1600x2560 @ 240 dpi = 1066 dp, three planes):
//
//   A RenderFlex overflowed by 676 pixels on the right.
//   Row  lib/presentation/component/orders_item.dart:200
//   constraints: BoxConstraints(0.0<=w<=314.0, ...)
//
// `OrdersItem` (templates/components/driver/orders_item.dart) draws the
// customer row - avatar, then the address and the name / phone lines.
// Those lines were sized to `MediaQuery.sizeOf(context).width - 124.w`,
// the SCREEN's width, which on a phone happens to be the card's width.
// Since 1.21.3 the card also renders in the profile host's DETAIL plane
// (OrderHistoryPane), (1066 - 2 * 14) / 3 = 346 dp wide at 1066 dp: the
// row had 314 dp and was handed 32 + 16 + (1066 - 124) = 990 (ScreenUtil
// is 1:1 on a non-compact window). So the column must be Expanded - it
// takes the ROW's width - and the screen-derived figure may only ever CAP
// the lines (a phone keeps exactly the width it always had), never size
// them.
//
// These tests read the template source. The template cannot be pumped
// from this package: its `order_detail.dart` import chain carries the
// composer's `${package}` placeholder, exactly why the driver home tests
// read theirs. The composed-host reproduction (the card in a 346 dp
// detail plane at 1066 dp, the 800 dp and phone controls) lives in the
// 1.21.4 changelog entry.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _template = 'templates/components/driver/orders_item.dart';
const String _screenWidth = 'MediaQuery.sizeOf(context).width - 124.w';

void main() {
  // Code only: the template's own comments name the screen-width figure
  // while explaining why it is now a cap.
  final src = File(_template)
      .readAsLinesSync()
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');

  // The customer row is the one that draws the address.
  final address = src.indexOf('order.address?.address');

  test('the template still draws the customer address', () {
    expect(address, isNot(-1));
  });

  test('nothing on the card is SIZED to the screen width', () {
    expect(
      src,
      isNot(contains('width: $_screenWidth')),
      reason:
          'a SizedBox(width: screen - 124.w) overflows the row the '
          'moment the card renders in a plane narrower than the screen',
    );
  });

  test('the address / customer column is Expanded inside its row', () {
    final expanded = src.lastIndexOf('Expanded(', address);
    expect(expanded, isNot(-1));
    final column = src.indexOf('Column(', expanded);
    expect(column, isNot(-1));
    expect(
      column,
      lessThan(address),
      reason: 'the Expanded must wrap the column that holds the address',
    );
    final between = src.substring(expanded, column);
    expect(between, contains('child:'));
    expect(
      between,
      isNot(contains(';')),
      reason:
          'no statement may separate the two - the column is the '
          'Expanded child, not a sibling',
    );
    // No Row opens between that Expanded and the address: the Expanded
    // belongs to the customer row itself, not to the name / phone row
    // nested further down.
    expect(src.substring(expanded, address), isNot(contains('Row(')));
  });

  test('the screen-derived width is only ever a maxWidth cap', () {
    final caps = RegExp(
      r'maxWidth:\s*' + RegExp.escape(_screenWidth),
    ).allMatches(src).length;
    // The address line and the name / phone line.
    expect(caps, 2);
    expect(
      _screenWidth.allMatches(src).length,
      caps,
      reason: 'every use of the screen width must be one of those caps',
    );
  });
}
