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


// Long content folds with a fade and Show more; short content is left as it is.

import 'package:base_sdk/base_sdk.dart' show ExpandableContent;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: SizedBox(width: 300, child: child))));

void main() {
  testWidgets('short content shows whole, with no button', (t) async {
    await t.pumpWidget(_app(const ExpandableContent(collapsedHeight: 100, child: SizedBox(height: 60, child: Text('hi')))));
    await t.pump();
    expect(find.text('Show more'), findsNothing);
    expect(t.getSize(find.byType(ExpandableContent)).height, 60);
  });

  testWidgets('long content folds, opens and folds again', (t) async {
    await t.pumpWidget(_app(const ExpandableContent(collapsedHeight: 100, child: SizedBox(height: 500, child: Text('long')))));
    await t.pump();
    expect(find.text('Show more'), findsOneWidget);
    expect(find.byKey(const ValueKey('expandable_content.fade')), findsOneWidget);
    expect(t.getSize(find.byKey(const ValueKey('expandable_content.fade'))).height, 100);
    await t.tap(find.text('Show more'));
    await t.pump();
    expect(find.text('Show less'), findsOneWidget);
    expect(find.byKey(const ValueKey('expandable_content.fade')), findsNothing);
    expect(t.getSize(find.byType(ExpandableContent)).height, greaterThan(500));
    await t.tap(find.text('Show less'));
    await t.pump();
    expect(find.text('Show more'), findsOneWidget);
  });

  testWidgets('a little past the limit is not folded', (t) async {
    await t.pumpWidget(_app(const ExpandableContent(collapsedHeight: 100, child: SizedBox(height: 130, child: Text('x')))));
    await t.pump();
    expect(find.text('Show more'), findsNothing);
  });
}
