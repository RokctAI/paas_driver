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

/// Installer-convention DI hook: the composed app's generated `main.dart`
/// calls `RevenueSdkDependencies.register(GetIt.instance)` for every installed
/// SDK, importing it through the barrel — so this file must compile in every
/// role-stripped cache and cannot import anything under `lib/src/manager/` or
/// `lib/src/driver/` (the composer's strip_unused_role_folders deletes the
/// non-matching role folder from an app's cache).
///
/// The concrete repositories are role code, so their registration lives with
/// them: `ManagerRevenueDependencies` (src/manager/di/manager_revenue_di.dart)
/// registers [SellerStatisticsRepositoryFacade] and `DriverRevenueDependencies`
/// (src/driver/di/driver_revenue_di.dart) registers
/// [CourierStatisticsRepositoryFacade]. Each role's hook is wired by that
/// role's `di_hooks` entry in this SDK's manifest (`revenue-manager-role-di` /
/// `revenue-driver-role-di`), which injects the call into the generated
/// `main.dart` via a direct `src/` import — same stance as zones_sdk's empty
/// `ZonesSdkDependencies.register`, where role wiring lives outside the common
/// register. A compose that loses that hook fails at first resolve of the
/// facade, loudly, not at compile time.
class RevenueSdkDependencies {
  static void register(GetIt getIt) {
    // Intentionally empty — see class doc. Role repositories are registered
    // by the host calling its role's hook, e.g. a driver app:
    //
    //   DriverRevenueDependencies.register(getIt);
  }
}
