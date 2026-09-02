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

import '../domain/interface/processing_repository_facade.dart';
import '../infrastructure/services/local_processing_repository.dart';

class ProcessingSdkDependencies {
  /// Registers the offline default. Hosts that persist contract state on a
  /// backend register their own [ProcessingRepositoryFacade] BEFORE calling
  /// this (an existing registration is left untouched).
  static void register(GetIt getIt) {
    if (!getIt.isRegistered<ProcessingRepositoryFacade>()) {
      getIt.registerLazySingleton<ProcessingRepositoryFacade>(
        () => LocalProcessingRepository(),
      );
    }
  }
}
