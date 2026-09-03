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

import 'package:revenue_sdk/src/common/infrastructure/models/response/deposit_request_record.dart';

/// Plain immutable state for the deposit approval queue (design strip
/// frame 49i, manager side). Hand-written `copyWith`, matching the sibling
/// slices, so it stays analyzable without a build_runner pass.
class DepositApprovalsState {
  const DepositApprovalsState({
    this.pending = const [],
    this.isLoading = false,
    this.failed = false,
    this.loadedOnce = false,
    this.resolvingId,
    this.lastResolution,
  });

  /// What is waiting, oldest first — the order a queue is worked in.
  final List<DepositRequestRecord> pending;

  final bool isLoading;
  final bool failed;

  /// A read has completed, so an empty queue means "nothing waiting", not
  /// "we have not looked yet".
  final bool loadedOnce;

  /// The request whose decision is in flight; its two buttons go inert so a
  /// double-tap cannot send the decision twice.
  final String? resolvingId;

  /// The last decision the server accepted on this session.
  final DepositResolution? lastResolution;

  DepositApprovalsState copyWith({
    List<DepositRequestRecord>? pending,
    bool? isLoading,
    bool? failed,
    bool? loadedOnce,
    String? resolvingId,
    bool clearResolvingId = false,
    DepositResolution? lastResolution,
  }) =>
      DepositApprovalsState(
        pending: pending ?? this.pending,
        isLoading: isLoading ?? this.isLoading,
        failed: failed ?? this.failed,
        loadedOnce: loadedOnce ?? this.loadedOnce,
        resolvingId: clearResolvingId ? null : (resolvingId ?? this.resolvingId),
        lastResolution: lastResolution ?? this.lastResolution,
      );
}
