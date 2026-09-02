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
import 'package:base_sdk/src/domain/interface/banners.dart';
import 'package:promotions_sdk/src/common/infrastructure/repositories/banners_repository.dart';
import 'package:promotions_sdk/src/common/infrastructure/repositories/mock_banners_repository.dart';

/// Installer-convention DI hook: the composed app's generated `main.dart`
/// calls `PromotionsSdkDependencies.register(GetIt.instance)` for every
/// installed SDK. Registers this SDK's repositories against their base_sdk
/// facades (idempotently, so hand-wired hosts can call it too).
class PromotionsSdkDependencies {
  static void register(GetIt getIt) {
    if (!getIt.isRegistered<BannersRepositoryFacade>()) {
      getIt.registerSingleton<BannersRepositoryFacade>(
        AppConstants.isDemo ? MockBannersRepository() : BannersRepository(),
      );
    }
  }
}
