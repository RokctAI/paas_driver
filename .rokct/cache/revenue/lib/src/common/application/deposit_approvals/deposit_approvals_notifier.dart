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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Imported directly (not via handlers.dart) because ApiResult's `when` is an
// EXTENSION declared in the generated `api_result.freezed.dart` part — it is
// only in scope for a library that imports its defining library, which is
// what the sibling notifiers do too.
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/error_presenter.dart';

import 'package:revenue_sdk/src/common/application/deposit_approvals/deposit_approvals_state.dart';
import 'package:revenue_sdk/src/common/domain/interface/deposit_approval.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/deposit_request_record.dart';

/// Radio-level connectivity gate, injectable so the page's tests can run
/// the whole decision path against a fake repository without a platform
/// channel. Defaults to [AppConnectivity.connectivity].
typedef ApprovalConnectivityCheck = Future<bool> Function();

/// The manager's deposit queue (design strip frame 49i): read what is
/// waiting, approve or reject each one.
///
/// The SERVER is the authority on both decisions — role, no self-review,
/// one credit per request, a reason on every refusal. This slice relays
/// the decision, drops the row the server accepted, and holds no truth
/// about the money.
///
/// ERROR WORDING (Ray's standing rule): a person facing failure sees ONE
/// friendly line, never the server's sentence; the verbatim detail rides
/// [ErrorPresenter.showTechnical] to telemetry. [ErrorPresenter.show] is
/// deliberately not used — Frappe answers a `frappe.throw` with 417,
/// inside `show`'s definitive-4xx band.
class DepositApprovalsNotifier extends StateNotifier<DepositApprovalsState> {
  DepositApprovalsNotifier(
    this._repository, {
    ApprovalConnectivityCheck? isOnline,
  })  : _isOnline = isOnline ?? AppConnectivity.connectivity,
        super(const DepositApprovalsState());

  final DepositApprovalRepositoryFacade _repository;
  final ApprovalConnectivityCheck _isOnline;

  /// Telemetry bucket for everything that goes wrong on this surface.
  static const String errorType = 'manager_deposit_approval';

  /// The queue. Failures are stated on the page itself, never as a toast.
  Future<void> load({BuildContext? context}) async {
    if (state.isLoading) return;
    if (!await _isOnline()) {
      if (context != null && context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
      return;
    }
    state = state.copyWith(isLoading: true, failed: false);
    final response = await _repository.listPendingDepositRequests();
    response.when(
      success: (rows) => state = state.copyWith(
        pending: rows,
        isLoading: false,
        loadedOnce: true,
      ),
      failure: (_, __) => state = state.copyWith(
        isLoading: false,
        failed: true,
        loadedOnce: true,
      ),
    );
  }

  /// Approve: the credit happens server-side, once. On success the row
  /// leaves the queue and [onDone] hears what was credited.
  Future<void> approve({
    required BuildContext context,
    required DepositRequestRecord request,
    void Function(DepositResolution resolution)? onDone,
  }) =>
      _resolve(
        context: context,
        request: request,
        call: () => _repository.approveDepositRequest(request.id),
        op: 'approve_deposit_request',
        friendlyKey: 'we_couldnt_approve_that_deposit_nothing_has_changed',
        onDone: onDone,
      );

  /// Reject: needs a reason the driver will read (chip 981). Nothing
  /// moves — nothing was held.
  Future<void> reject({
    required BuildContext context,
    required DepositRequestRecord request,
    required String reason,
    void Function(DepositResolution resolution)? onDone,
  }) {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) return Future.value();
    return _resolve(
      context: context,
      request: request,
      call: () => _repository.rejectDepositRequest(request.id, reason: trimmed),
      op: 'reject_deposit_request',
      friendlyKey: 'we_couldnt_reject_that_deposit_nothing_has_changed',
      onDone: onDone,
    );
  }

  Future<void> _resolve({
    required BuildContext context,
    required DepositRequestRecord request,
    required Future<ApiResult<DepositResolution>> Function() call,
    required String op,
    required String friendlyKey,
    void Function(DepositResolution resolution)? onDone,
  }) async {
    if (state.resolvingId != null) return;
    // Claimed BEFORE the first await, so two taps in the same frame cannot
    // both pass the guard.
    state = state.copyWith(resolvingId: request.id);

    if (!await _isOnline()) {
      state = state.copyWith(clearResolvingId: true);
      if (context.mounted) AppHelpers.showNoConnectionSnackBar(context);
      return;
    }

    final response = await call();
    response.when(
      success: (resolution) {
        state = state.copyWith(
          clearResolvingId: true,
          lastResolution: resolution,
          pending: state.pending.where((r) => r.id != request.id).toList(),
        );
        onDone?.call(resolution);
      },
      failure: (failure, status) {
        state = state.copyWith(clearResolvingId: true);
        if (context.mounted) {
          ErrorPresenter.showTechnical(
            context,
            type: errorType,
            detail: failure,
            statusCode: status,
            friendly: AppHelpers.getTranslation(friendlyKey),
            extra: {'op': op, 'request': request.id},
          );
        }
      },
    );
  }
}
