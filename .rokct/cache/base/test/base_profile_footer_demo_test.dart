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
// still report Offline. A demo SESSION (a server-marked demo account on a
// real build, DemoSession) reads as Online the same way, and the row
// follows the switch while it is on screen - sign-out happens from the
// profile, so the dot must fall back to the real probe on the flip.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:base_sdk/src/application/profile/profile_host_capabilities.dart';
import 'package:base_sdk/src/presentation/pages/profile/profile_host_scope.dart';
import 'package:base_sdk/src/presentation/pages/profile/widgets/base_profile_footer.dart';
import 'package:base_sdk/src/services/demo_session.dart';
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

  tearDown(() async {
    // The overrides are app-global; never let one test leak into the next.
    ProfileMetaRow.isDemoOverride = null;
    await DemoSession.instance.clear();
    DemoSession.isDemoOverride = null;
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

  group('ProfileMetaRow Online/Offline dot under the runtime demo session',
      () {
    setUp(() {
      // A real build, and the row asks the session rather than a stand-in.
      DemoSession.isDemoOverride = false;
      ProfileMetaRow.isDemoOverride = null;
    });

    testWidgets('a demo session on a real build reads as Online',
        (tester) async {
      await DemoSession.instance.activate();

      await tester.pumpWidget(_host(const ProfileMetaRow()));
      await tester.pumpAndSettle();

      expect(find.text('Online'), findsOneWidget);
      expect(find.text('Offline'), findsNothing);
    });

    testWidgets('the row follows the session while it is on screen',
        (tester) async {
      await tester.pumpWidget(_host(const ProfileMetaRow()));
      await tester.pump();
      // Session off, no backend answering: never a session-granted Online.
      expect(find.text('Online'), findsNothing);

      await DemoSession.instance.activate();
      await tester.pump();
      await tester.pump();
      expect(find.text('Online'), findsOneWidget);

      // Sign-out ends the session with the profile still up: the dot
      // drops the session's answer and goes back to the real probe.
      await DemoSession.instance.clear();
      await tester.pump();
      await tester.pump();
      expect(find.text('Online'), findsNothing);
    });
  });
}
