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

// "Welcome back" (Ray, 2026-11-27): after Log out kept the account on this
// device, the sign-in page offers it in one tap, with "Use another account",
// "Remove from this device" and Skip.

import 'package:base_sdk/src/services/remembered_account.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auth_sdk/src/common/presentation/pages/auth/login/welcome_back_entry.dart';

void main() {
  testWidgets('shows the kept account and routes each action', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final taps = <String>[];
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: WelcomeBackEntry(
              account: RememberedAccount(
                name: 'Thandi Mokoena',
                email: 'thandi@example.co.za',
                savedAt: DateTime(2026, 11, 27),
              ),
              onContinue: () => taps.add('continue'),
              onAnotherAccount: () => taps.add('another'),
              onRemove: () => taps.add('remove'),
              onSkip: () => taps.add('skip'),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Thandi Mokoena'), findsOneWidget);
    expect(find.text('thandi@example.co.za'), findsOneWidget);
    await tester.tap(find.byKey(WelcomeBackEntry.accountKey));
    await tester.tap(find.byKey(WelcomeBackEntry.anotherKey));
    await tester.tap(find.byKey(WelcomeBackEntry.removeKey));
    expect(taps, ['continue', 'another', 'remove']);
    expect(tester.takeException(), isNull);
  });
}
