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


// The driver's Profile settings as the profile's DETAIL PANE at plane
// widths (Ray 2026-09-08, the sheet fork ruling: "sheet = PHONE, plane
// widths get a pane"; base_sdk 1.60.11). What each test pins:
//
//   * a shell that supplies a settings detail registers it as the host's
//     edit-profile detail, and one that supplies none registers nothing
//     (the sheet everywhere, as before);
//   * on a three-plane screen tapping the Profile settings row replaces
//     Order history in the third plane with the settings form - no sheet
//     opens - and the header pencil reaches the same pane; the corner
//     Back returns to Order history;
//   * on a phone the row opens the sheet path exactly as before.

import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:base_sdk/src/presentation/adaptive/planes.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
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
import 'package:remixicon/remixicon.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeUserRepository extends Fake implements UserRepositoryFacade {}

const _historyKey = ValueKey('driver-order-history-detail');
const _settingsKey = ValueKey('driver-profile-settings-detail');

void _noop(BuildContext context) {}

DriverProfileActions _actions({
  WidgetBuilder? orderHistoryDetail,
  WidgetBuilder? profileSettingsDetail,
  void Function(BuildContext context) onProfileSettings = _noop,
}) => DriverProfileActions(
  onProfileSettings: onProfileSettings,
  onDeliveryZone: _noop,
  onOrders: _noop,
  onParcels: _noop,
  onNotifications: _noop,
  onOrderHistory: _noop,
  onParcelHistory: _noop,
  onIncome: _noop,
  onLanguage: _noop,
  onDeleteAccount: null,
  onOnlineHelper: _noop,
  orderHistoryDetail: orderHistoryDetail,
  profileSettingsDetail: profileSettingsDetail,
);

Widget _history(BuildContext context) =>
    const SizedBox.expand(key: _historyKey);

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

  /// The planes the settings form was granted, once open.
  Planes? settingsPlanes;
  Widget settings(BuildContext context) {
    settingsPlanes = Planes.of(context);
    return const SizedBox.expand(key: _settingsKey);
  }

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

  Finder settingsRow() =>
      find.text(AppHelpers.getTranslation(TrKeys.profileSettings));

  group('DriverProfileSections.register', () {
    test('a settings detail becomes the host\'s edit-profile detail', () {
      DriverProfileSections.register(
        actions: _actions(profileSettingsDetail: settings),
      );
      expect(ProfileSectionRegistry.I.editProfileDetailBuilder, isNotNull);
    });

    test('no detail, no registration - the sheet everywhere', () {
      DriverProfileSections.register(actions: _actions());
      expect(ProfileSectionRegistry.I.editProfileDetailBuilder, isNull);
    });

    test('an edit detail another SDK registered first is kept', () {
      Widget other(BuildContext context) => const SizedBox();
      ProfileSectionRegistry.I.editProfileDetailBuilder = other;
      DriverProfileSections.register(
        actions: _actions(profileSettingsDetail: settings),
      );
      expect(ProfileSectionRegistry.I.editProfileDetailBuilder, same(other));
    });
  });

  testWidgets(
    'three planes (1066 dp): Profile settings replaces Order history in '
    'the third plane - no sheet; the corner Back returns to Order history',
    (tester) async {
      var sheets = 0;
      DriverProfileSections.register(
        actions: _actions(
          orderHistoryDetail: _history,
          profileSettingsDetail: settings,
          onProfileSettings: (_) => sheets++,
        ),
      );
      await pumpRoutedProfile(tester, width: 1066, height: 800);
      expect(tester.takeException(), isNull);
      expect(find.byKey(_historyKey), findsOneWidget);
      expect(find.byKey(_settingsKey), findsNothing);
      expect(find.byType(FloatingBackPill), findsNothing);

      await tester.ensureVisible(settingsRow());
      await tester.tap(settingsRow());
      await tester.pump();
      expect(find.byKey(_settingsKey), findsOneWidget);
      expect(find.byKey(_historyKey), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
      expect(sheets, 0);

      // The LAST plane, the profile keeping its two.
      final planes = settingsPlanes!;
      expect(planes.count, 3);
      expect(planes.index, 2);
      expect(planes.span, 1);
      final planeWidth = (1066 - 2 * _gap) / 3;
      final twoPlanes = 2 * planeWidth + _gap;
      expect(
        tester.getRect(profilePlanes()).right,
        moreOrLessEquals(twoPlanes, epsilon: 0.5),
      );
      expect(
        tester.getRect(find.byKey(_settingsKey)).left,
        moreOrLessEquals(twoPlanes + _gap, epsilon: 0.5),
      );

      // The pill pops the pane back to Order history, not the route.
      expect(find.byType(FloatingBackPill), findsOneWidget);
      await tester.tap(find.byType(FloatingBackPill));
      await tester.pump();
      expect(find.byKey(_historyKey), findsOneWidget);
      expect(find.byKey(_settingsKey), findsNothing);
      expect(find.byType(FloatingBackPill), findsNothing);
      expect(sheets, 0);
    },
  );

  testWidgets('three planes: the header pencil opens the same pane', (
    tester,
  ) async {
    var sheets = 0;
    DriverProfileSections.register(
      actions: _actions(
        orderHistoryDetail: _history,
        profileSettingsDetail: settings,
        onProfileSettings: (_) => sheets++,
      ),
    );
    // The shell's pencil wiring: the sheet, which the host tries after
    // the pane.
    ProfileSectionRegistry.I.onEditProfile = (_) => sheets++;
    await pumpRoutedProfile(tester, width: 1066, height: 800);

    await tester.tap(find.byIcon(Remix.pencil_line));
    await tester.pump();
    expect(find.byKey(_settingsKey), findsOneWidget);
    expect(find.byKey(_historyKey), findsNothing);
    expect(settingsPlanes!.index, 2);
    expect(sheets, 0);
  });

  testWidgets('phone (390 dp): no seam - the row opens the sheet path as '
      'before', (tester) async {
    var sheets = 0;
    DriverProfileSections.register(
      actions: _actions(
        orderHistoryDetail: _history,
        profileSettingsDetail: settings,
        onProfileSettings: (_) => sheets++,
      ),
    );
    await pumpRoutedProfile(tester, width: 390, height: 844);
    expect(find.byType(PlaneHost), findsNothing);

    await tester.ensureVisible(settingsRow());
    await tester.tap(settingsRow());
    await tester.pump();
    expect(sheets, 1);
    expect(find.byKey(_settingsKey), findsNothing);
  });
}
