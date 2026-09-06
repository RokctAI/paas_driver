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

// The profile footer's Online/Offline dot is backed by a real api_status
// probe of the tenant backend. A demo build (--dart-define=IS_DEMO=true)
// has no backend by design, so that probe can only ever fail there, and
// every demo build drew a red Offline - the guided tour's profile still
// captured it verbatim. In a demo build the dot must read as connected
// without probing; a real build must still ask the backend, and with no
// backend answering (this test has no connectivity plugin and no server)
// still report Offline.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:base_sdk/src/application/profile/profile_host_capabilities.dart';
import 'package:base_sdk/src/presentation/pages/profile/profile_host_scope.dart';
import 'package:base_sdk/src/presentation/pages/profile/widgets/base_profile_footer.dart';
import 'package:base_sdk/src/services/local_storage.dart';

/// Pumps the meta row under the anonymous host scope (no account facade),
/// so the usage badge - which needs a signed-in user and an HttpService -
/// stays out of the row and only the dot is under test.
Widget _host(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(800, 600),
    builder: (context, _) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: ProfileHostScope(
            capabilities: const ProfileHostCapabilities(
              hasAccount: false,
              hasShops: false,
              hasGallery: false,
            ),
            child: child,
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  tearDown(() {
    // The override is app-global; never let one test leak into the next.
    ProfileMetaRow.isDemoOverride = null;
  });

  group('ProfileMetaRow Online/Offline dot', () {
    testWidgets('a demo build reads as Online without a backend',
        (tester) async {
      // isDemo is a compile-time constant; the override is the only way a
      // test can stand in a demo build.
      ProfileMetaRow.isDemoOverride = true;

      await tester.pumpWidget(_host(const ProfileMetaRow()));
      await tester.pumpAndSettle();

      expect(find.text('Online'), findsOneWidget);
      expect(find.text('Offline'), findsNothing);
    });

    testWidgets('a real build with no backend answering still reads Offline',
        (tester) async {
      ProfileMetaRow.isDemoOverride = false;

      await tester.pumpWidget(_host(const ProfileMetaRow()));
      await tester.pumpAndSettle();

      expect(find.text('Offline'), findsOneWidget);
      expect(find.text('Online'), findsNothing);
    });
  });
}
