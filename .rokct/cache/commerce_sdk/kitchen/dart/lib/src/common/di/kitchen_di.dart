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
import 'package:kitchen_sdk/src/common/domain/interface/kitchens.dart';
import 'package:kitchen_sdk/src/manager/infrastructure/repositories/kitchens_repository.dart';

/// Installer-convention DI hook: the composed app's generated `main.dart` calls
/// `KitchenSdkDependencies.register(GetIt.instance)` for every installed SDK.
/// Registers idempotently so hand-wired hosts can call it too.
class KitchenSdkDependencies {
  static void register(GetIt getIt) {
    if (!getIt.isRegistered<KitchensRepositoryFacade>()) {
      getIt.registerSingleton<KitchensRepositoryFacade>(KitchensRepository());
    }
  }
}
