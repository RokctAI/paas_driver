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
// what the sibling statistics and withdraw notifiers do too.
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/error_presenter.dart';

import 'package:revenue_sdk/src/common/domain/interface/courier_statistics.dart';
import 'package:revenue_sdk/src/common/domain/interface/driver_wallet.dart';
import 'package:revenue_sdk/src/common/infrastructure/wallet_balance_cache.dart';
import 'package:revenue_sdk/src/driver/application/wallet/wallet_state.dart';

/// The driver wallet plane's reads (design strip frame 49f).
///
/// ERROR WORDING (Ray's standing rule): a driver-facing failure shows ONLY
/// a friendly line. It never shows the raw server message and never
/// distinguishes one backend cause from another — a missing Wallet row, a
/// def the composed app does not whitelist and a provider outage all read
/// the same on screen. The admin-grade detail (verbatim server message +
/// status code) rides the ONE telemetry door,
/// [ErrorPresenter.showTechnical] -> `TelemetryClient.logError` -> backend
/// `log_frontend_error`.
///
/// [ErrorPresenter.show] is deliberately NOT used, for the same reason the
/// withdraw notifier avoids it: it echoes a definitive 4xx verbatim, and
/// Frappe answers a `frappe.throw` with 417 — inside that band — so the
/// server's own wording would reach the driver. The unconditional technical
/// branch is the only one that honours the rule on this surface.
class DriverWalletNotifier extends StateNotifier<DriverWalletState> {
  DriverWalletNotifier(this._wallet, this._statistics)
      : super(const DriverWalletState());

  final DriverWalletRepositoryFacade _wallet;

  /// Reused as-is for the month's fees; this SDK already owns the courier
  /// report seam and its DI registration, so the wallet plane adds no new
  /// dependency to read it.
  final CourierStatisticsRepositoryFacade _statistics;

  /// Telemetry bucket for everything that goes wrong on this surface.
  static const String errorType = 'driver_wallet_plane';

  /// How many rows the statement shows before "See all movements".
  static const int foldedRowCount = 6;

  /// How many rows are fetched. The endpoint's own paging default is 20;
  /// asking for the same keeps one screen's worth of history in hand
  /// without a second round trip when the driver unfolds it.
  static const int fetchLimit = 20;

  /// Loads everything the plane draws.
  ///
  /// Each read is independent: a statement that will not load must not
  /// hide the balance, and a balance that will not load must not hide the
  /// statement. Only ONE friendly line is raised per failed load.
  Future<void> load(BuildContext context) async {
    if (!await AppConnectivity.connectivity()) {
      if (context.mounted) AppHelpers.showNoConnectionSnackBar(context);
      return;
    }
    await Future.wait([
      _loadBalance(context),
      _loadMovements(context),
      _loadFeesThisMonth(),
    ]);
  }

  /// Unfolds the statement to every row already fetched. No screen is
  /// opened: none has been approved.
  void showAllMovements() =>
      state = state.copyWith(showAllMovements: true);

  Future<void> _loadBalance(BuildContext context) async {
    state = state.copyWith(isLoadingBalance: true, balanceFailed: false);
    final response = await _wallet.getBalance();
    response.when(
      success: (balance) {
        state = state.copyWith(
          balance: balance,
          isLoadingBalance: false,
        );
        // Every other driver money surface reads the cached profile
        // wallet; writing the authoritative figure there is what stops
        // the income page and the profile page disagreeing with this one.
        WalletBalanceCache.mirror(balance);
      },
      failure: (failure, status) {
        state = state.copyWith(
          isLoadingBalance: false,
          balanceFailed: true,
        );
        if (context.mounted) {
          ErrorPresenter.showTechnical(
            context,
            type: errorType,
            detail: failure,
            statusCode: status,
            extra: const {'read': 'balance'},
          );
        }
      },
    );
  }

  Future<void> _loadMovements(BuildContext context) async {
    state = state.copyWith(isLoadingMovements: true, movementsFailed: false);
    final response = await _wallet.getMovements(limit: fetchLimit);
    response.when(
      success: (movements) {
        state = state.copyWith(
          movements: movements,
          isLoadingMovements: false,
        );
      },
      failure: (failure, status) {
        state = state.copyWith(
          isLoadingMovements: false,
          movementsFailed: true,
        );
        if (context.mounted) {
          ErrorPresenter.showTechnical(
            context,
            type: errorType,
            detail: failure,
            statusCode: status,
            extra: const {'read': 'movements'},
          );
        }
      },
    );
  }

  /// Gross delivery fees for the current calendar month.
  ///
  /// `get_deliveryman_order_report` sums the `delivery_fee` of Delivered
  /// orders and parcel orders in the window
  /// (`zones/delivery/.../delivery_man.py:722-800`) — that is fees EARNED,
  /// before the delivery commission the settlement bills back, so it is
  /// labelled "fees earned" and never "your income".
  ///
  /// Silent on failure ON PURPOSE: it is one supporting line on a card
  /// whose subject is the balance, and a second friendly snackbar for a
  /// secondary figure would teach a driver to dismiss the first one. The
  /// line simply does not render.
  Future<void> _loadFeesThisMonth() async {
    final now = DateTime.now();
    final response = await _statistics.getStatistics(
      startTime: DateTime(now.year, now.month, 1),
      endTime: now,
    );
    response.when(
      success: (data) {
        final fees = data.data?.totalPrice;
        if (fees != null) state = state.copyWith(feesThisMonth: fees);
      },
      failure: (_, __) {},
    );
  }
}
