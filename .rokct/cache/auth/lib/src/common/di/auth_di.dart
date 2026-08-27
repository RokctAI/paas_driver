// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
