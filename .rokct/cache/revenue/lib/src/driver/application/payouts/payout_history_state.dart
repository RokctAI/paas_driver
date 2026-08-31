// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
