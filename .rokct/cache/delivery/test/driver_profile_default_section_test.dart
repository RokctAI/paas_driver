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

// The driver profile's DEFAULT section in the plane host's detail plane
// (tablet audit 2026-09-07, 16-users_profile: the third plane stayed
// empty). What a later edit could quietly undo, and what each test pins:
//
//   * a shell that supplies an Order history detail makes the rows section
//     the registry's default, and one that supplies none leaves no default
//     (the plane stays bare, every row pushes);
//   * on a three-plane screen base's routed host lands with the driver's
//     detail open in the third plane on the FIRST frame, and the profile
//     keeps its two planes;
//   * the Order history row opens the detail in the host on planes and
//     falls back to its push on a phone - the phone path is byte-identical.

import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:base_sdk/src/presentation/adaptive/planes.dart';
import 'package:base_sdk/src/presentation/pages/profile/generic_profile_page.dart';
import 'package:base_sdk/src/presentation/pages/profile/generic_profile_route_page.dart';
import 'package:base_sdk/src/presentation/pages/profile/profile_section_registry.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:delivery_sdk/src/driver/presentation/profile/driver_profile_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The page never reaches the repository here (no stored token, so
/// fetchUser returns before its first call); the notifier only needs a
/// constructible instance - the driver compose registers this facade and
/// no shops/gallery one, which base_sdk >= 1.58.0 resolves lazily.
class _FakeUserRepository extends Fake implements UserRepositoryFacade {}

const _detailKey = ValueKey('driver-order-history-detail');

void _noop(BuildContext context) {}

DriverProfileActions _actions({
  WidgetBuilder? orderHistoryDetail,
  void Function(BuildContext context) onOrderHistory = _noop,
}) => DriverProfileActions(
  onProfileSettings: _noop,
  onDeliveryZone: _noop,
  onOrders: _noop,
  onParcels: _noop,
  onNotifications: _noop,
  onOrderHistory: onOrderHistory,
  onParcelHistory: _noop,
  onIncome: _noop,
  onLanguage: _noop,
  onDeleteAccount: null,
  onOnlineHelper: _noop,
  orderHistoryDetail: orderHistoryDetail,
);

Widget _detail(BuildContext context) => const SizedBox.expand(key: _detailKey);

/// The seam PlaneHost puts between planes (its default gap).
const _gap = 14.0;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocalStorage.init();
    if (!getIt.isRegistered<UserRepositoryFacade>()) {
      getIt.registerSingleton<UserRepositoryFacade>(_FakeUserRepository());
    }
  });

  setUp(ProfileSectionRegistry.I.reset);
  tearDown(ProfileSectionRegistry.I.reset);

  /// base's routed host as the driver shell renders it at plane widths,
  /// pumped ONE frame - the first frame the profile lands with.
  Future<void> pumpRoutedProfile(
    WidgetTester tester, {
    required double width,
    required double height,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: Size(width, height),
          builder: (context, _) => const MaterialApp(
            home: GenericProfileRoutePage(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Finder profilePlanes() => find.byKey(
    ValueKey('plane-page-${GenericProfileRoutePage.planePageName}'),
  );

  group('DriverProfileSections.register', () {
    test('an Order history detail makes the rows section the default', () {
      DriverProfileSections.register(
        actions: _actions(orderHistoryDetail: _detail),
      );
      final registry = ProfileSectionRegistry.I;
      expect(registry.defaultSectionId, DriverProfileSections.rowsId);
      expect(registry.defaultSection?.id, DriverProfileSections.rowsId);
      expect(registry.defaultSection?.detailBuilder, isNotNull);
    });

    test('no detail, no default - the plane stays bare', () {
      DriverProfileSections.register(actions: _actions());
      final registry = ProfileSectionRegistry.I;
      expect(registry.defaultSectionId, isNull);
      expect(registry.defaultSection, isNull);
      expect(
        registry.section(DriverProfileSections.rowsId)?.detailBuilder,
        isNull,
      );
    });

    test('a default another SDK named first is kept', () {
      ProfileSectionRegistry.I.defaultSectionId = 'other.section';
      DriverProfileSections.register(
        actions: _actions(orderHistoryDetail: _detail),
      );
      expect(ProfileSectionRegistry.I.defaultSectionId, 'other.section');
    });
  });

  group('on planes', () {
    testWidgets(
      'three planes (1066 dp): the detail is open in the third plane on '
      'the first frame; the profile keeps two',
      (tester) async {
        DriverProfileSections.register(
          actions: _actions(orderHistoryDetail: _detail),
        );
        await pumpRoutedProfile(tester, width: 1066, height: 800);
        expect(tester.takeException(), isNull);

        expect(find.byType(PlaneHost), findsOneWidget);
        expect(find.byType(GenericProfilePage), findsOneWidget);
        expect(find.byKey(_detailKey), findsOneWidget);

        final planeWidth = (1066 - 2 * _gap) / 3;
        final twoPlanes = 2 * planeWidth + _gap;
        expect(
          tester.getRect(profilePlanes()).right,
          moreOrLessEquals(twoPlanes, epsilon: 0.5),
        );
        expect(
          tester.getRect(find.byKey(_detailKey)).left,
          moreOrLessEquals(twoPlanes + _gap, epsilon: 0.5),
        );
      },
    );

    testWidgets('two planes (800 dp): nothing is seeded; the Order history '
        'row opens the detail beside the profile, not a push', (tester) async {
      var pushes = 0;
      DriverProfileSections.register(
        actions: _actions(
          orderHistoryDetail: _detail,
          onOrderHistory: (_) => pushes++,
        ),
      );
      await pumpRoutedProfile(tester, width: 800, height: 1280);
      expect(find.byKey(_detailKey), findsNothing);

      final row = find.text(AppHelpers.getTranslation(TrKeys.orderHistory));
      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pump();
      expect(find.byKey(_detailKey), findsOneWidget);
      expect(pushes, 0);
    });
  });

  testWidgets('phone (390 dp): no seam - the Order history row pushes as '
      'before', (tester) async {
    var pushes = 0;
    DriverProfileSections.register(
      actions: _actions(
        orderHistoryDetail: _detail,
        onOrderHistory: (_) => pushes++,
      ),
    );
    await pumpRoutedProfile(tester, width: 390, height: 844);
    expect(find.byType(PlaneHost), findsNothing);
    expect(find.byKey(_detailKey), findsNothing);

    final row = find.text(AppHelpers.getTranslation(TrKeys.orderHistory));
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pump();
    expect(pushes, 1);
    expect(find.byKey(_detailKey), findsNothing);
  });
}
