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

import '../models/loyalty_models.dart';

/// Consumer-owned boundary for loyalty persistence/transport.
///
/// The host app registers a backend-backed implementation when the platform
/// exposes loyalty endpoints; a local offline implementation over base_sdk's
/// shared database ships with this SDK as the default.
abstract class LoyaltyRepositoryFacade {
  Future<ApiResult<LoyaltyAccount>> getAccount({
    required String ownerId,
    String program,
  });

  Future<ApiResult<List<LoyaltyTransaction>>> getTransactions(
    String accountId,
  );

  /// Records a transaction and returns the account with its updated balance.
  Future<ApiResult<LoyaltyAccount>> record(LoyaltyTransaction transaction);
}
