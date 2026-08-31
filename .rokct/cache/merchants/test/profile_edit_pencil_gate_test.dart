// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// The user-card edit pencil gate (chip 109, approved frame 4d
// 2026-08-30): base_sdk's GenericProfilePage renders the identity-card
// pencil ONLY while ProfileSectionRegistry.I.onEditProfile is set — the
// manager hub shipped pencil-less because registerMerchantProfileSections
// never wired it (the gap Ray reported after the chip-243 shop-pencil
// move, commerce PR #80). Pins both sides of the gate the merchants
// wiring in restaurant_page.dart relies on: unset -> no pencil; wired
// (the `registry.onEditProfile ??= ...` block) -> the pencil renders on
// the user card and fires the callback. The wiring's target — base_sdk's
// shared EditProfileScreen sheet (base_sdk 1.45.0) — is imported here so
// this suite is also the compile gate proving the shared sheet resolves
// from merchants_sdk's dependency graph. (restaurant_page.dart itself
// lives in templates/ with `${package}` imports, so the registration
// function cannot be pumped directly — same constraint as the
// productivity gate suite.)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remixicon/remixicon.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/domain/interface/gallery.dart';
import 'package:base_sdk/src/domain/interface/shops.dart';
import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:base_sdk/src/presentation/pages/profile/edit_profile_sheet.dart';
import 'package:base_sdk/src/presentation/pages/profile/generic_profile_page.dart';
import 'package:base_sdk/src/presentation/pages/profile/profile_section_registry.dart';
import 'package:base_sdk/src/services/local_storage.dart';

// The page never touches the repositories in this test (no stored token,
// so fetchUser returns before its first repository call); the notifier
// only needs constructible instances — same harness as base_sdk's own
// generic_profile_spread_test.dart.
class _FakeUserRepository extends Fake implements UserRepositoryFacade {}

class _FakeShopsRepository extends Fake implements ShopsRepositoryFacade {}

class _FakeGalleryRepository extends Fake implements GalleryRepositoryFacade {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    getIt.registerSingleton<UserRepositoryFacade>(_FakeUserRepository());
    getIt.registerSingleton<ShopsRepositoryFacade>(_FakeShopsRepository());
    getIt
        .registerSingleton<GalleryRepositoryFacade>(_FakeGalleryRepository());
  });

  setUp(() => ProfileSectionRegistry.I.reset());

  Future<void> pumpHost(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(390, 1400),
          builder: (context, _) =>
              const MaterialApp(home: GenericProfilePage()),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('while onEditProfile is unset the user card has NO pencil',
      (tester) async {
    // The shipped manager gap: no wiring, no pencil anywhere on the host
    // (the shop-row pencil is a section widget, not registered here).
    await pumpHost(tester);
    expect(find.byIcon(Remix.pencil_line), findsNothing);
  });

  testWidgets('wiring onEditProfile renders the user-card pencil once and '
      'the pencil fires it', (tester) async {
    // The restaurant_page.dart wiring shape: `registry.onEditProfile ??=`
    // opening base_sdk's shared sheet. The callback is recorded instead
    // of opening the real drag sheet; EditProfileScreen's import above
    // proves the shared component resolves for merchants_sdk.
    var opened = 0;
    ProfileSectionRegistry.I.onEditProfile ??= (context) => opened++;

    await pumpHost(tester);

    final pencil = find.byIcon(Remix.pencil_line);
    expect(pencil, findsOneWidget);

    await tester.tap(pencil);
    expect(opened, 1);

    // The wiring target stays constructible with the drag-sheet contract
    // the real callback uses (controller-fed).
    final controller = ScrollController();
    addTearDown(controller.dispose);
    expect(EditProfileScreen(controller: controller), isA<Widget>());
  });
}
