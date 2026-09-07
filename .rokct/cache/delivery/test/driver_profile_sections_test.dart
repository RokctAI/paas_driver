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


// The driver profile's contribution to base_sdk's generic profile host
// (design strip section 1 on the driver, tablet audit 2026-09-07 defect 3).
//
// What a later edit could quietly undo, and what each group pins:
//
//   * registration claims exactly the rows section, the Online helper
//     section and the base.footer slot, in that order, and a second
//     registration changes nothing;
//   * the row list keeps the retired page's ten rows in its order, and the
//     Profile settings row keeps the title users_sdk's tour fragment taps;
//   * Delete account is a row only while its action exists (demo builds
//     pass none);
//   * the stats row shows the three figures the old tiles showed.

import 'package:base_sdk/src/presentation/pages/profile/profile_section_registry.dart';
import 'package:base_sdk/src/presentation/pages/profile/widgets/base_profile_footer.dart';
import 'package:base_sdk/src/presentation/pages/profile/widgets/profile_nav_tile.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:delivery_sdk/src/driver/presentation/profile/driver_profile_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Size _phone = Size(390, 900);

void _noop(BuildContext context) {}

DriverProfileActions _actions({
  void Function(BuildContext context)? onDeleteAccount,
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
  onDeleteAccount: onDeleteAccount,
  onOnlineHelper: _noop,
);

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = _phone;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: _phone,
      builder: (context, _) => MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pump();
}

List<String> _rowTitles(WidgetTester tester) => tester
    .widgetList<ProfileNavTile>(find.byType(ProfileNavTile))
    .map((tile) => tile.title)
    .toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocalStorage.init();
    ProfileSectionRegistry.I.reset();
  });

  tearDown(ProfileSectionRegistry.I.reset);

  group('DriverProfileSections.register', () {
    test('claims rows, Online helper and the footer slot in order', () {
      DriverProfileSections.register(actions: _actions());
      final ids = ProfileSectionRegistry.I.sections.map((s) => s.id).toList();
      expect(ids, [
        DriverProfileSections.rowsId,
        DriverProfileSections.onlineHelperId,
        BaseProfileFooter.sectionId,
      ]);
      expect(
        DriverProfileSections.rowsOrder,
        lessThan(DriverProfileSections.onlineHelperOrder),
      );
      expect(
        DriverProfileSections.onlineHelperOrder,
        lessThan(BaseProfileFooter.sectionOrder),
      );
    });

    test('a second registration changes nothing', () {
      DriverProfileSections.register(actions: _actions());
      DriverProfileSections.register(actions: _actions());
      expect(ProfileSectionRegistry.I.sections.length, 3);
    });

    test('the footer slot stays claimed once the host fills defaults', () {
      DriverProfileSections.register(actions: _actions());
      ProfileSectionRegistry.I.ensureDefaultSections();
      expect(ProfileSectionRegistry.I.sections.length, 3);
    });
  });

  group('DriverProfileRows', () {
    testWidgets('keeps the ten rows in the retired order', (tester) async {
      await _pump(
        tester,
        DriverProfileRows(actions: _actions(onDeleteAccount: _noop)),
      );
      expect(tester.takeException(), isNull);
      expect(_rowTitles(tester), [
        AppHelpers.getTranslation(TrKeys.profileSettings),
        AppHelpers.getTranslation(TrKeys.deliveryZone),
        AppHelpers.getTranslation(TrKeys.orders),
        AppHelpers.getTranslation(TrKeys.parcels),
        AppHelpers.getTranslation(TrKeys.notifications),
        AppHelpers.getTranslation(TrKeys.orderHistory),
        AppHelpers.getTranslation(TrKeys.parcelHistory),
        AppHelpers.getTranslation(TrKeys.income),
        AppHelpers.getTranslation(TrKeys.language),
        AppHelpers.getTranslation(TrKeys.deleteAccount),
      ]);
    });

    testWidgets('hides Delete account without an action', (tester) async {
      await _pump(tester, DriverProfileRows(actions: _actions()));
      expect(find.byType(ProfileNavTile), findsNWidgets(9));
      final deleteAccount = AppHelpers.getTranslation(TrKeys.deleteAccount);
      expect(find.text(deleteAccount), findsNothing);
    });

    testWidgets('Profile settings is the tour finder and opens', (
      tester,
    ) async {
      var opened = 0;
      void open(BuildContext context) => opened++;
      await _pump(
        tester,
        DriverProfileRows(actions: _actions(onProfileSettings: open)),
      );
      final title = AppHelpers.getTranslation(TrKeys.profileSettings);
      expect(find.text(title), findsOneWidget);
      await tester.tap(find.text(title));
      await tester.pump();
      expect(opened, 1);
    });
  });

  group('DriverProfileStatsRow', () {
    testWidgets('shows balance, last profit and delivered', (tester) async {
      await _pump(
        tester,
        const DriverProfileStatsRow(
          balance: 1240,
          lastProfit: 85,
          deliveredOrders: 17,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        find.text(AppHelpers.getTranslation(TrKeys.balance)),
        findsOneWidget,
      );
      expect(
        find.text(AppHelpers.getTranslation(TrKeys.lastProfit)),
        findsOneWidget,
      );
      expect(
        find.text(AppHelpers.getTranslation(TrKeys.deliveredOrder)),
        findsOneWidget,
      );
      expect(find.text('17'), findsOneWidget);
    });
  });
}
