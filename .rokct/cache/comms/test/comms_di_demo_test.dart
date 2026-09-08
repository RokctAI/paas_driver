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


// comms_sdk's DI hook registers the settings repository against base_sdk's
// SettingsRepositoryFacade, picking the in-app-fixture twin for demo. The
// pick follows DemoSession.demoActive - a demo BUILD or a demo SESSION -
// and the singleton is swapped on every flip of the session, so a
// server-marked demo account signing in after boot is served the fixtures
// and a sign-out ending its session gets the real repository back.

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:base_sdk/src/domain/interface/settings.dart';
import 'package:base_sdk/src/services/demo_session.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:comms_sdk/src/common/di/comms_di.dart';
import 'package:comms_sdk/src/common/infrastructure/repositories/mock_settings_repository.dart';
import 'package:comms_sdk/src/common/infrastructure/repositories/settings_repository.dart';

/// A host's own facade, to prove the hook never replaces one it did not
/// register.
class _HostSettingsRepository extends MockSettingsRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GetIt getIt;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    // A real build: only the session can make it demo.
    DemoSession.isDemoOverride = false;
    getIt = GetIt.asNewInstance();
  });

  tearDown(() async {
    // The listener, the session and the override are app-global; never
    // let one test leak into the next.
    CommsSdkDependencies.stopFollowingDemoSession(getIt);
    await DemoSession.instance.clear();
    DemoSession.isDemoOverride = null;
    await getIt.reset();
  });

  group('CommsSdkDependencies and the runtime demo session', () {
    test('registers the real repository while the session is off', () {
      CommsSdkDependencies.register(getIt);

      expect(getIt<SettingsRepositoryFacade>(), isA<SettingsRepository>());
    });

    test('swaps to the demo twin on activate and back on clear', () async {
      CommsSdkDependencies.register(getIt);

      await DemoSession.instance.activate();
      expect(getIt<SettingsRepositoryFacade>(), isA<MockSettingsRepository>());

      await DemoSession.instance.clear();
      expect(getIt<SettingsRepositoryFacade>(), isA<SettingsRepository>());
    });

    test('registers the demo twin when the session is already on', () async {
      await DemoSession.instance.activate();

      CommsSdkDependencies.register(getIt);

      expect(getIt<SettingsRepositoryFacade>(), isA<MockSettingsRepository>());
    });

    test('a demo build serves the twin whatever the session says', () async {
      DemoSession.isDemoOverride = true;
      CommsSdkDependencies.register(getIt);
      expect(getIt<SettingsRepositoryFacade>(), isA<MockSettingsRepository>());

      await DemoSession.instance.activate();
      await DemoSession.instance.clear();
      expect(getIt<SettingsRepositoryFacade>(), isA<MockSettingsRepository>());
    });

    test('registering twice attaches one listener and one swap', () async {
      CommsSdkDependencies.register(getIt);
      CommsSdkDependencies.register(getIt);

      // removeListener drops ONE registration: had two been added, the
      // survivor would still swap on the flip below.
      CommsSdkDependencies.stopFollowingDemoSession(getIt);
      await DemoSession.instance.activate();

      expect(getIt<SettingsRepositoryFacade>(), isA<SettingsRepository>());
    });

    test('a facade the host registered first is never replaced', () async {
      getIt.registerSingleton<SettingsRepositoryFacade>(
        _HostSettingsRepository(),
      );

      CommsSdkDependencies.register(getIt);
      await DemoSession.instance.activate();
      expect(getIt<SettingsRepositoryFacade>(), isA<_HostSettingsRepository>());

      await DemoSession.instance.clear();
      expect(getIt<SettingsRepositoryFacade>(), isA<_HostSettingsRepository>());
    });
  });
}
