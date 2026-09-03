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
// EXTENSION declared in the generated `api_result.freezed.dart` part.
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/error_presenter.dart';

import 'package:revenue_sdk/src/common/domain/interface/driver_payout.dart';
import 'package:revenue_sdk/src/common/application/payouts/payout_history_state.dart';

/// The payout trail's one read (design strip frame 49k).
///
/// This screen is a READ ONLY. Resolution is desk-side — `Paid` and
/// `Rejected` are written by a person on the admin side — and the one
/// self-service transition the backend does allow, cancelling a still
/// `Requested` payout (`payout.py:388-427`), is deliberately NOT offered
/// here: who may cancel and until when is a policy question the frame
/// flagged for Ray rather than settling.
///
/// ERROR WORDING as everywhere else on the driver's money: one friendly
/// line on screen, the verbatim detail to telemetry through
/// [ErrorPresenter.showTechnical]. [ErrorPresenter.show] is deliberately
/// NOT used — Frappe answers a `frappe.throw` with 417, which falls inside
/// `show`'s definitive-4xx band and would echo the server's wording to the
/// driver.
class PayoutHistoryNotifier extends StateNotifier<PayoutHistoryState> {
  PayoutHistoryNotifier(this._repository)
      : super(const PayoutHistoryState());

  final DriverPayoutRepositoryFacade _repository;

  /// Telemetry bucket for everything that goes wrong on this surface.
  static const String errorType = 'driver_payout_history';

  Future<void> load(BuildContext context) async {
    if (state.isLoading) return;
    if (!await AppConnectivity.connectivity()) {
      if (context.mounted) AppHelpers.showNoConnectionSnackBar(context);
      return;
    }
    state = state.copyWith(isLoading: true, failed: false);
    final response = await _repository.listPayoutRequests();
    response.when(
      success: (requests) {
        state = state.copyWith(
          requests: requests,
          isLoading: false,
          loadedOnce: true,
        );
      },
      failure: (failure, status) {
        state = state.copyWith(
          isLoading: false,
          failed: true,
          loadedOnce: true,
        );
        if (context.mounted) {
          ErrorPresenter.showTechnical(
            context,
            type: errorType,
            detail: failure,
            statusCode: status,
          );
        }
      },
    );
  }
}
