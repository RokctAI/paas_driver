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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:base_sdk/src/services/local_storage.dart';
import 'package:auth_sdk/src/common/presentation/pages/auth/login/login_card_entry.dart';
import 'package:auth_sdk/src/common/presentation/pages/auth/login/login_embedded_slots.dart';
import 'package:auth_sdk/src/common/services/entry_config.dart';

Widget _host() => ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: LoginCardEntry(
            slots: const LoginEmbeddedSlots(),
            onLogin: () {},
            onRegister: () {},
            onSkip: () {},
            onSocial: (_) {},
          ),
        ),
      ),
    );

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });
  tearDown(AuthEntryConfig.reset);

  test('an app that declares nothing keeps the photo login', () {
    AuthEntryConfig.reset();
    expect(AuthEntryConfig.layout, AuthEntryLayout.photo);
    expect(AuthEntryConfig.showsRegister, isTrue);
    expect(AuthEntryConfig.socialSignIns, isEmpty);
  });

  test('Apple and Facebook stay behind the same gate as the login sheet', () {
    // appleAndFacebookSignInVerified is false today: the sheet hides them,
    // so the card must too. Google is not behind that gate.
    expect(socialSignInShown(AuthSocialSignIn.google), isTrue);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(socialSignInShown(AuthSocialSignIn.google), isFalse,
        reason: 'no Google on iOS');
    debugDefaultTargetPlatformOverride = null;
    expect(socialSignInShown(AuthSocialSignIn.facebook), isFalse);
    expect(socialSignInShown(AuthSocialSignIn.apple), isFalse);
  });

  testWidgets('card: showsRegister false hides Register, unverified socials hidden',
      (tester) async {
    AuthEntryConfig.layout = AuthEntryLayout.card;
    AuthEntryConfig.showsRegister = false;
    AuthEntryConfig.socialSignIns = const [
      AuthSocialSignIn.google,
      AuthSocialSignIn.apple,
      AuthSocialSignIn.facebook,
    ];
    await tester.pumpWidget(_host());
    await tester.pump();
    expect(find.textContaining(RegExp('Register', caseSensitive: false)), findsNothing);
    expect(find.textContaining(RegExp('Facebook', caseSensitive: false)), findsNothing);
    expect(find.textContaining(RegExp('Apple', caseSensitive: false)), findsNothing);
    expect(find.textContaining(RegExp('Google', caseSensitive: false)), findsOneWidget);
  });

  testWidgets('card: Register shows by default', (tester) async {
    AuthEntryConfig.layout = AuthEntryLayout.card;
    await tester.pumpWidget(_host());
    await tester.pump();
    expect(find.textContaining(RegExp('Register', caseSensitive: false)), findsOneWidget);
  });
}
