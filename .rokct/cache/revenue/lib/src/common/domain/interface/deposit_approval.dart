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

import 'package:revenue_sdk/src/common/infrastructure/models/response/deposit_request_record.dart';

/// The manager's side of the bank-deposit route (design strip frame 49i):
/// what is waiting, and the two decisions.
///
/// Server: pay `wallet/frappe/src/tenant/api/wallet.py`, whitelisted as
/// `{app_name}.api.wallet.*`. Both decisions are role-gated there
/// (`DEPOSIT_APPROVER_ROLES`) and a request is never resolvable by its own
/// requester; the client draws the queue and relays the decision, it
/// holds no truth about the money.
abstract class DepositApprovalRepositoryFacade {
  /// `list_pending_deposit_requests()` — oldest first, with the driver's
  /// name on each row. Refused (417) for a caller without an approver role.
  Future<ApiResult<List<DepositRequestRecord>>> listPendingDepositRequests();

  /// `approve_deposit_request(request_id)` — credits the driver's wallet
  /// ONCE, inside the same transaction as the status write.
  Future<ApiResult<DepositResolution>> approveDepositRequest(String requestId);

  /// `reject_deposit_request(request_id, reason)` — refuses with a reason
  /// the driver will read (chip 981). Nothing moves: nothing was held.
  Future<ApiResult<DepositResolution>> rejectDepositRequest(
    String requestId, {
    required String reason,
  });
}
