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
// only in scope for a library that imports its defining library.
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/error_presenter.dart';

import 'package:delivery_sdk/src/driver/application/load/load_draft.dart';
import 'package:delivery_sdk/src/driver/application/load/load_state.dart';
import 'package:delivery_sdk/src/driver/domain/interface/load.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/driver_load.dart';

/// Radio-level connectivity gate, injectable so the screens' tests can run
/// the whole flow against a fake repository without a platform channel.
typedef ConnectivityCheck = Future<bool> Function();

/// The driver's consignment load (van sales).
///
/// ERROR WORDING (Ray's standing rule): a driver facing failure sees ONE
/// friendly line, never the server's sentence; the verbatim detail rides
/// [ErrorPresenter.showTechnical] to telemetry. Frappe answers a
/// `frappe.throw` with 417, inside [ErrorPresenter.show]'s definitive-4xx
/// band, which is why `show` is deliberately not used here.
///
/// EVERY WRITE RE-READS ITS LOAD FROM THE ANSWER. `create_load_sale`,
/// `return_load` and `close_load` all hand back the load as it now stands,
/// so the slice replaces its row from the answer rather than decrementing
/// anything locally. A client that did its own subtraction would drift from
/// the figure the server validates the next sale against.
class DriverLoadNotifier extends StateNotifier<DriverLoadState> {
  DriverLoadNotifier(this._repository, {ConnectivityCheck? isOnline})
      : _isOnline = isOnline ?? AppConnectivity.connectivity,
        super(const DriverLoadState());

  final DriverLoadRepositoryFacade _repository;
  final ConnectivityCheck _isOnline;

  /// Telemetry bucket for everything that goes wrong on this surface.
  static const String errorType = 'driver_load';

  /// Reads every load issued to this driver. Safe to call on every entry:
  /// a re-entry while a read is already in flight is a no-op.
  Future<void> load({BuildContext? context}) async {
    if (state.isLoading) return;
    if (!await _isOnline()) {
      if (context != null && context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
      return;
    }
    state = state.copyWith(isLoading: true, failed: false);
    final response = await _repository.getMyLoad();
    response.when(
      success: (loads) {
        state = state.copyWith(
          loads: loads,
          isLoading: false,
          loadedOnce: true,
        );
      },
      failure: (failure, status) {
        state = state.copyWith(isLoading: false, failed: true);
        _report(
          context,
          failure: failure,
          status: status,
          op: 'get_my_load',
          friendly: 'we_couldnt_read_your_load_try_again_in_a_moment',
        );
      },
    );
  }

  /// The sale at the door. [draft] is the picked quantities; the cash
  /// figure the success sheet names is struck HERE, from the load's own
  /// unit prices, so the screen and the sheet cannot disagree.
  ///
  /// [poi] is the point of interest the driver named, when he named one. It
  /// is passed through untouched — this slice does not read points and must
  /// not start deciding which one a sale belongs to.
  ///
  /// Returns the sale on success and null on failure — the caller opens its
  /// sheet on a non-null answer and says nothing extra on a null one,
  /// because this method has already spoken.
  Future<DriverLoadSale?> sell({
    required DriverLoad load,
    required LoadDraft draft,
    String? customer,
    String? note,
    String? poi,
    BuildContext? context,
  }) async {
    final movements = draft.movementsFor(load);
    if (movements.isEmpty || state.isSubmitting) return null;
    if (!await _isOnline()) {
      if (context != null && context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
      return null;
    }
    final amount = draft.totalFor(load);
    state = state.copyWith(isSubmitting: true);
    final response = await _repository.createLoadSale(
      loadOrder: load.id,
      items: movements,
      customer: customer,
      note: note,
      poi: poi,
    );
    DriverLoadSale? sold;
    response.when(
      success: (sale) {
        sold = sale.withAmount(amount);
        state = state.copyWith(
          isSubmitting: false,
          lastSale: sold,
          loads: _replacing(sale.load),
        );
      },
      failure: (failure, status) {
        state = state.copyWith(isSubmitting: false);
        _report(
          context,
          failure: failure,
          status: status,
          op: 'create_load_sale',
          friendly: 'we_couldnt_record_that_sale_try_again',
        );
      },
    );
    return sold;
  }

  /// Unsold stock handed back to the shop. True when the server took it.
  Future<bool> returnStock({
    required DriverLoad load,
    required LoadDraft draft,
    BuildContext? context,
  }) async {
    final movements = draft.movementsFor(load);
    if (movements.isEmpty || state.isSubmitting) return false;
    if (!await _isOnline()) {
      if (context != null && context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
      return false;
    }
    state = state.copyWith(isSubmitting: true);
    final response = await _repository.returnLoad(
      loadOrder: load.id,
      items: movements,
    );
    var returned = false;
    response.when(
      success: (updated) {
        returned = true;
        state = state.copyWith(
          isSubmitting: false,
          loads: _replacing(updated),
        );
      },
      failure: (failure, status) {
        state = state.copyWith(isSubmitting: false);
        _report(
          context,
          failure: failure,
          status: status,
          op: 'return_load',
          friendly: 'we_couldnt_record_that_return_try_again',
        );
      },
    );
    return returned;
  }

  /// Closes the load. The variance is charged to the driver's wallet at the
  /// load price server-side; what comes back is the closed load with the
  /// per-line variance the summary reads. Idempotent server-side, so a
  /// second attempt after a lost answer is safe.
  Future<DriverLoad?> close({
    required DriverLoad load,
    BuildContext? context,
  }) async {
    if (state.isSubmitting) return null;
    if (!await _isOnline()) {
      if (context != null && context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
      return null;
    }
    state = state.copyWith(isSubmitting: true);
    final response = await _repository.closeLoad(loadOrder: load.id);
    DriverLoad? closed;
    response.when(
      success: (updated) {
        closed = updated;
        state = state.copyWith(
          isSubmitting: false,
          closedLoad: updated,
          loads: _replacing(updated),
        );
      },
      failure: (failure, status) {
        state = state.copyWith(isSubmitting: false);
        _report(
          context,
          failure: failure,
          status: status,
          op: 'close_load',
          friendly: 'we_couldnt_close_that_load_try_again',
        );
      },
    );
    return closed;
  }

  /// The held list with [updated] swapped in by id. A load the list has
  /// never seen is appended rather than dropped; a null answer leaves the
  /// list exactly as it was.
  List<DriverLoad> _replacing(DriverLoad? updated) {
    if (updated == null || updated.id.isEmpty) return state.loads;
    var replaced = false;
    final next = state.loads.map((load) {
      if (load.id != updated.id) return load;
      replaced = true;
      return updated;
    }).toList();
    if (!replaced) next.add(updated);
    return List<DriverLoad>.unmodifiable(next);
  }

  void _report(
    BuildContext? context, {
    required String failure,
    required int status,
    required String op,
    required String friendly,
  }) {
    if (context == null || !context.mounted) return;
    ErrorPresenter.showTechnical(
      context,
      type: errorType,
      detail: failure,
      statusCode: status,
      friendly: AppHelpers.getTranslation(friendly),
      extra: {'op': op},
    );
  }
}
