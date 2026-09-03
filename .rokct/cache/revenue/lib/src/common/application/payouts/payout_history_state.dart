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

import 'package:revenue_sdk/src/common/infrastructure/models/response/payout_request_record.dart';

/// Plain immutable state for the payout trail (design strip frame 49k).
class PayoutHistoryState {
  const PayoutHistoryState({
    this.requests = const [],
    this.isLoading = false,
    this.failed = false,
    this.loadedOnce = false,
  });

  /// Newest first, as `list_payout_requests` serves them.
  final List<PayoutRequestRecord> requests;

  final bool isLoading;

  /// The read did not land. One friendly line says so; the real cause has
  /// already gone to telemetry.
  final bool failed;

  /// True once a read has completed, successfully or not. Distinguishes
  /// "he has never withdrawn" from "we have not looked yet" — an empty
  /// trail is a real answer and must not be drawn before it is one.
  final bool loadedOnce;

  PayoutHistoryState copyWith({
    List<PayoutRequestRecord>? requests,
    bool? isLoading,
    bool? failed,
    bool? loadedOnce,
  }) =>
      PayoutHistoryState(
        requests: requests ?? this.requests,
        isLoading: isLoading ?? this.isLoading,
        failed: failed ?? this.failed,
        loadedOnce: loadedOnce ?? this.loadedOnce,
      );
}
