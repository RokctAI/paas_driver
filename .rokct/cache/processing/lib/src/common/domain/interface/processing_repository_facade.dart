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

import 'package:base_sdk/base_sdk.dart';

/// Consumer-owned persistence/transport boundary for the engine.
///
/// The host app decides where contract state lives (backend endpoint, local
/// database, or both) and registers an implementation via
/// ProcessingSdkDependencies.register. A local offline implementation
/// backed by base_sdk's shared database ships with this SDK.
abstract class ProcessingRepositoryFacade {
  Future<ApiResult<List<ProcessingContract>>> getContracts({String? type});

  Future<ApiResult<ProcessingContract?>> getContract(String contractId);

  Future<ApiResult<ProcessingContract>> saveContract(
    ProcessingContract contract,
  );

  Future<ApiResult<void>> deleteContract(String contractId);
}
