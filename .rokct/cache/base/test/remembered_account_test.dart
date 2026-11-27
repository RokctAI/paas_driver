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

// Log out keeps a few account details for up to 30 days (Ray, 2026-11-27,
// approved after the Claude app's Log out dialog), unless "Remove from this
// device" is ticked. Never a token: only name, email/phone and picture.

import 'package:base_sdk/src/models/data/profile_data.dart';
import 'package:base_sdk/src/presentation/pages/profile/generic_profile_page.dart';
import 'package:base_sdk/src/services/remembered_account.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final user = ProfileData(
    firstname: 'Thandi',
    lastname: 'Mokoena',
    email: 'thandi@example.co.za',
    img: 'https://x/t.png',
  );

  test('remembers name, email and picture, and reads them back', () async {
    await RememberedAccount.remember(user);
    final a = await RememberedAccount.read();
    expect(a!.name, 'Thandi Mokoena');
    expect(a.login, 'thandi@example.co.za');
    expect(a.img, 'https://x/t.png');
    expect(a.initial, 'T');
  });

  test('falls back to the phone when there is no email', () async {
    await RememberedAccount.remember(
      ProfileData(firstname: 'Sipho', phone: '+27711234567'),
    );
    expect((await RememberedAccount.read())!.login, '+27711234567');
  });

  test('keeps nothing for a user with neither email nor phone', () async {
    await RememberedAccount.remember(ProfileData(firstname: 'Nobody'));
    expect(await RememberedAccount.read(), isNull);
  });

  test('drops it after 30 days', () async {
    final t = DateTime(2026, 11, 27);
    await RememberedAccount.remember(user, now: t);
    expect(
      await RememberedAccount.read(now: t.add(const Duration(days: 29))),
      isNotNull,
    );
    expect(
      await RememberedAccount.read(now: t.add(const Duration(days: 31))),
      isNull,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(RememberedAccount.storageKey), isNull);
  });

  test('forget removes it', () async {
    await RememberedAccount.remember(user);
    await RememberedAccount.forget();
    expect(await RememberedAccount.read(), isNull);
  });

  testWidgets('the dialog reports the Remove tick to Log out', (tester) async {
    bool? removed;
    await tester.binding.setSurfaceSize(const Size(1200, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: LogoutDialogBody(
              onCancel: () {},
              onLogout: (r) => removed = r,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(LogoutDialogBody.confirmKey));
    expect(removed, isFalse);
    await tester.tap(find.byKey(LogoutDialogBody.removeKey));
    await tester.pump();
    await tester.tap(find.byKey(LogoutDialogBody.confirmKey));
    expect(removed, isTrue);
  });
}
