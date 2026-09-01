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

/// Plain immutable state, matching the statistics slice (a hand-written
/// `copyWith` keeps `revenue_sdk` analyzable without a `build_runner`
/// pass).
class WithdrawState {
  const WithdrawState({
    this.isSubmitting = false,
    this.lastRequestId,
    this.lastAmount,
    this.newBalance,
  });

  /// A request is in flight; the sheet's commit button goes inert so a
  /// double-tap cannot fire two holds.
  final bool isSubmitting;

  /// `Wallet Payout Request` row name of the last accepted request.
  final String? lastRequestId;

  /// The amount the server actually held.
  final num? lastAmount;

  /// The wallet balance AFTER the hold — the money has already left.
  final num? newBalance;

  WithdrawState copyWith({
    bool? isSubmitting,
    String? lastRequestId,
    num? lastAmount,
    num? newBalance,
  }) =>
      WithdrawState(
        isSubmitting: isSubmitting ?? this.isSubmitting,
        lastRequestId: lastRequestId ?? this.lastRequestId,
        lastAmount: lastAmount ?? this.lastAmount,
        newBalance: newBalance ?? this.newBalance,
      );
}
