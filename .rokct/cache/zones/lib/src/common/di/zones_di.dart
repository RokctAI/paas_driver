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

import 'package:base_sdk/base_sdk.dart' show DemoFixtures;
import 'package:get_it/get_it.dart';

/// Host asset directory holding zones_sdk's demo platform fixtures
/// (`<cmd>.json`), installed from `templates/assets/demo/zones`.
const String zonesDemoFixtureDirectory = 'assets/demo/zones';

/// zones_sdk's DI entry point, called from the host app's generated `main()`.
///
/// Registers nothing in GetIt today; it only registers the demo fixture
/// directory (see [zonesDemoFixtureDirectory]). zones_sdk's only cross-SDK need is
/// [DeliveryZonesFacade], and under ADR-005 the implementation is the host
/// app's to supply — it wraps whichever SDK actually stores the courier's
/// profile. `deliveryZoneProvider` resolves that facade from `GetIt` at build
/// time and falls back to a failing stand-in when the host has not registered
/// one, so composing zones_sdk without wiring it degrades visibly rather than
/// crashing at startup.
///
/// The class exists regardless because the composer generates a
/// `ZonesSdkDependencies.register(GetIt.instance)` call into every host that
/// lists this SDK; without it the host does not compile.
class ZonesSdkDependencies {
  static void register(GetIt getIt) {
    // Demo runs the REAL repository: base_sdk's DemoGatewayInterceptor
    // answers the zone cmds from these fixtures while DemoSession.demoActive.
    DemoFixtures.registerAssetDirectory(zonesDemoFixtureDirectory);
    // Intentionally empty — see class doc. Host-supplied adapters are
    // registered by the app, e.g.:
    //
    //   getIt.registerLazySingleton<DeliveryZonesFacade>(
    //     () => DriverDeliveryZonesAdapter(),
    //   );
  }
}
