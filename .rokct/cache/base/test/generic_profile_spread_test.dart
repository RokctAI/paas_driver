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


// GenericProfilePage self-spread (the approved plane proposal, frame 1c):
// granted planes by a PlaneHost above, the page spreads its registered
// sections across them — three balanced columns at three planes, two at
// two, the untouched phone list at one.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/domain/interface/gallery.dart';
import 'package:base_sdk/src/domain/interface/shops.dart';
import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:base_sdk/src/presentation/adaptive/planes.dart';
import 'package:base_sdk/src/presentation/pages/profile/generic_profile_page.dart';
import 'package:base_sdk/src/presentation/pages/profile/profile_section.dart';
import 'package:base_sdk/src/presentation/pages/profile/profile_section_registry.dart';
import 'package:base_sdk/src/services/local_storage.dart';

// The page never touches the repositories in this test (no stored token,
// so fetchUser returns before its first repository call); the notifier
// only needs constructible instances.
class _FakeUserRepository extends Fake implements UserRepositoryFacade {}

class _FakeShopsRepository extends Fake implements ShopsRepositoryFacade {}

class _FakeGalleryRepository extends Fake implements GalleryRepositoryFacade {}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    getIt.registerSingleton<UserRepositoryFacade>(_FakeUserRepository());
    getIt.registerSingleton<ShopsRepositoryFacade>(_FakeShopsRepository());
    getIt
        .registerSingleton<GalleryRepositoryFacade>(_FakeGalleryRepository());
  });

  setUp(() {
    ProfileSectionRegistry.I.reset();
    for (var i = 0; i < 5; i++) {
      ProfileSectionRegistry.I.register(
        ProfileSection(
          id: 'section$i',
          order: i * 10,
          builder: (_) => SizedBox(
            key: ValueKey('section$i'),
            height: 40,
            width: double.infinity,
          ),
        ),
      );
    }
  });

  Future<void> pumpProfile(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: Size(width, 1400),
          builder: (context, _) => MaterialApp(
            home: PlaneHost(
              stack: [
                PlanePage(
                  name: 'profile',
                  span: PlaneSpan.all,
                  builder: (_) => const GenericProfilePage(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// The distinct left edges of the registered sections — one per column
  /// the page spread itself across.
  Set<double> columnEdges(WidgetTester tester) {
    final edges = <double>{};
    for (var i = 0; i < 5; i++) {
      edges.add(
        tester
            .getTopLeft(find.byKey(ValueKey('section$i')))
            .dx
            .roundToDouble(),
      );
    }
    return edges;
  }

  testWidgets('three planes: sections spread across three balanced columns',
      (tester) async {
    await pumpProfile(tester, 900);
    for (var i = 0; i < 5; i++) {
      expect(find.byKey(ValueKey('section$i')), findsOneWidget);
    }
    expect(columnEdges(tester), hasLength(3));
  });

  testWidgets('two planes: sections spread across two columns',
      (tester) async {
    await pumpProfile(tester, 700);
    for (var i = 0; i < 5; i++) {
      expect(find.byKey(ValueKey('section$i')), findsOneWidget);
    }
    expect(columnEdges(tester), hasLength(2));
  });

  testWidgets('one plane: the untouched phone list — one column',
      (tester) async {
    await pumpProfile(tester, 500);
    for (var i = 0; i < 5; i++) {
      expect(find.byKey(ValueKey('section$i')), findsOneWidget);
    }
    expect(columnEdges(tester), hasLength(1));
    // The phone layout is the plain ListView, not the spread body.
    expect(find.byType(ListView), findsOneWidget);
  });

  testWidgets('registry order reads down the columns left to right',
      (tester) async {
    await pumpProfile(tester, 900);
    // Contiguous balanced split preserves registry order: a later
    // section is never in an earlier column.
    double dxOf(int i) =>
        tester.getTopLeft(find.byKey(ValueKey('section$i'))).dx;
    for (var i = 0; i < 4; i++) {
      expect(dxOf(i + 1), greaterThanOrEqualTo(dxOf(i)));
    }
  });
}
