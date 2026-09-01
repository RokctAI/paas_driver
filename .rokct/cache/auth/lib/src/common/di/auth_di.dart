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
import 'package:base_sdk/src/domain/interface/auth.dart';
import 'package:base_sdk/src/sync/sync_engine.dart';
import 'package:auth_sdk/src/common/infrastructure/repositories/auth_repository.dart';
import 'package:auth_sdk/src/common/infrastructure/repositories/mock_auth_repository.dart';
import 'package:auth_sdk/src/common/infrastructure/services/auth_sync_handler.dart';

/// Installer-convention DI hook: the composed app's generated `main.dart`
/// calls `AuthSdkDependencies.register(GetIt.instance)` for every
/// installed SDK. Registers this SDK's repositories against their base_sdk
/// facades (idempotently, so hand-wired hosts can call it too).
class AuthSdkDependencies {
  static void register(GetIt getIt) {
    if (!getIt.isRegistered<AuthRepositoryFacade>()) {
      getIt.registerSingleton<AuthRepositoryFacade>(
        AppConstants.isDemo ? MockAuthRepository() : AuthRepository(),
      );
    }
    // Attach the auth.register push handler so offline registrations drain
    // to the backend. BaseSdkDependencies.register puts the engine in
    // get_it before feature SDKs run; the process-singleton fallback keeps
    // hand-wired hosts that skipped it working. registerHandler replaces
    // any previous handler, so this is idempotent too. Requires
    // base_sdk >= 1.5.0 (SyncEngine/SyncHandler).
    final engine =
        getIt.isRegistered<SyncEngine>() ? getIt<SyncEngine>() : SyncEngine();
    engine.registerHandler(AuthSyncHandler.opType, AuthSyncHandler());
  }
}
