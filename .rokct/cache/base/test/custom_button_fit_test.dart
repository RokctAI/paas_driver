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

// CustomButton's label shrinks only when it would not fit (Ray 2026-11-27:
// Log out buttons side by side), and still lays out with unbounded width
// (a fixed `weight` straight in a Row, as comms_sdk's clear-card dialog does).

import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child) => ScreenUtilInit(
  designSize: const Size(390, 844),
  builder: (_, __) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  testWidgets('two fixed-weight buttons straight in a Row', (tester) async {
    await tester.pumpWidget(
      host(
        Row(
          children: [
            CustomButton(title: 'Cancel', weight: 120, onPressed: () {}),
            CustomButton(title: 'Clear', weight: 120, onPressed: () {}),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Clear'), findsOneWidget);
  });

  testWidgets('half-width buttons with a long label do not overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 260,
          child: Row(
            children: [
              Expanded(
                child: CustomButton(title: 'Kanselleer', onPressed: () {}),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(title: 'Meld af', onPressed: () {}),
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
