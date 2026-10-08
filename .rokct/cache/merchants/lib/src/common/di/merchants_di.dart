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

import 'package:get_it/get_it.dart';
import 'package:base_sdk/base_sdk.dart' show DemoFixtures;
import 'package:base_sdk/src/domain/interface/shops.dart';
import 'package:merchants_sdk/src/common/infrastructure/repositories/shops_repository.dart';

/// Host asset directory holding merchants_sdk's demo platform fixtures
/// (`<cmd>.json`), installed from `templates/assets/demo/merchants`.
const String merchantsDemoFixtureDirectory = 'assets/demo/merchants';

/// Installer-convention DI hook: the composed app's generated `main.dart`
/// calls `MerchantsSdkDependencies.register(GetIt.instance)` for every
/// installed SDK. Registers this SDK's repositories against their base_sdk
/// facades (idempotently, so hand-wired hosts can call it too).
///
/// Demo runs the REAL repositories: base_sdk's DemoGatewayInterceptor
/// answers every platform cmd they send from the `<cmd>.json` fixtures in
/// [merchantsDemoFixtureDirectory] while DemoSession.demoActive (read per
/// request, so a demo account signing in later is honoured), and an
/// unknown cmd fails loudly with DemoFixtureMissing. The fixtures carry
/// the two demo shops, the manager's own shop, its working days, Quick
/// flow settings and the POS checkout's demo customer.
class MerchantsSdkDependencies {
  static void register(GetIt getIt) {
    DemoFixtures.registerAssetDirectory(merchantsDemoFixtureDirectory);
    if (!getIt.isRegistered<ShopsRepositoryFacade>()) {
      getIt.registerSingleton<ShopsRepositoryFacade>(ShopsRepository());
    }
  }
}
