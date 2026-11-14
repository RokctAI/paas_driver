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

import 'package:base_sdk/src/presentation/components/blur_wrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => BlurWrap.blurDisabled = false);

  Widget wrap() => const Directionality(
        textDirection: TextDirection.ltr,
        child: BlurWrap(
          radius: BorderRadius.all(Radius.circular(8)),
          child: SizedBox(width: 10, height: 10),
        ),
      );

  testWidgets('BlurWrap blurs its backdrop by default', (tester) async {
    BlurWrap.blurDisabled = false;
    await tester.pumpWidget(wrap());
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.byType(ClipRRect), findsOneWidget);
  });

  testWidgets('BlurWrap skips the backdrop blur in the tour build',
      (tester) async {
    BlurWrap.blurDisabled = true;
    await tester.pumpWidget(wrap());
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.byType(ClipRRect), findsOneWidget);
  });
}
