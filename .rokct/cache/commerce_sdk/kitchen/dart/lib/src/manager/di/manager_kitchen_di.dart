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

import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:kitchen_sdk/src/manager/domain/interface/kitchen_orders.dart';
import 'package:kitchen_sdk/src/manager/infrastructure/repositories/demo_kitchen_orders_repository.dart';
import 'package:kitchen_sdk/src/manager/infrastructure/repositories/kitchen_orders_repository.dart';

/// Manager-role DI hook (orders_sdk's `ManagerOrdersDependencies` pattern):
/// wired through the manifest's app_type.manager `di_hooks`, importing this
/// file via its direct `src/` path, so a compose without the manager role
/// never touches this slice. Registers idempotently so hand-wired hosts can
/// call it too.
class ManagerKitchenDependencies {
  static void register(GetIt getIt) {
    // Demo-gated like merchants_sdk's POS seams and products_sdk's catalog
    // facades: --dart-define=IS_DEMO=true serves a seeded kitchen service
    // from memory, so the Kitchen tab shows a live queue with ticking
    // clocks and dish pills instead of its empty state, with zero backend
    // contact. The production path is untouched.
    if (!getIt.isRegistered<KitchenOrdersRepositoryFacade>()) {
      getIt.registerSingleton<KitchenOrdersRepositoryFacade>(
        AppConstants.isDemo
            ? DemoKitchenOrdersRepository()
            : KitchenOrdersRepository(),
      );
    }
  }
}
