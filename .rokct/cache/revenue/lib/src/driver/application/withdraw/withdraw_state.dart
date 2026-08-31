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
