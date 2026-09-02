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

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:get_it/get_it.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/response/single_user_response.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/response/users_paginate_response.dart';

/// Narrow seam for the POS flow's walk-in customer picker (ADR-005).
///
/// users_sdk owns customer records; orders_sdk owns the `select_user_page`
/// screen and its create-customer modal. The manager host installs an adapter
/// (`templates/adapters/manager/orders_adapters.dart`) binding this to
/// users_sdk's facade.
///
/// `createUser` is the fork's known backend gap: users_sdk's `register_user`
/// is self-signup, and no seller-scoped create-walk-in-customer endpoint
/// exists yet — see `docs/frappe-endpoint-contract.md`. The contract is
/// declared anyway so the UI and adapter are ready when the endpoint lands;
/// an unwired or unimplemented call fails visibly through [ApiResult.failure].
abstract class PosCustomersFacade {
  Future<ApiResult<UsersPaginateResponse>> searchUsers({
    String? query,
    int? page,
  });

  Future<ApiResult<SingleUserResponse>> createUser({
    required String firstname,
    required String lastname,
    required String phone,
    required String email,
  });
}

/// GetIt-or-stand-in resolution used by `orderUserProvider`/
/// `createUserProvider` (zones_sdk's fallback pattern): an unwired host
/// surfaces a named failure instead of an empty customer list.
PosCustomersFacade resolvePosCustomersFacade() {
  final getIt = GetIt.instance;
  return getIt.isRegistered<PosCustomersFacade>()
      ? getIt<PosCustomersFacade>()
      : const _UnwiredPosCustomers();
}

class _UnwiredPosCustomers implements PosCustomersFacade {
  const _UnwiredPosCustomers();

  static const _message =
      'No PosCustomersFacade is registered: the host app has not '
      'installed/wired orders_adapters.dart to a users repository.';

  @override
  Future<ApiResult<UsersPaginateResponse>> searchUsers({
    String? query,
    int? page,
  }) async =>
      const ApiResult.failure(error: _message, statusCode: 501);

  @override
  Future<ApiResult<SingleUserResponse>> createUser({
    required String firstname,
    required String lastname,
    required String phone,
    required String email,
  }) async =>
      const ApiResult.failure(error: _message, statusCode: 501);
}
