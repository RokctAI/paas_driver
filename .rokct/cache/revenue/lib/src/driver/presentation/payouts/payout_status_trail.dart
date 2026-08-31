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

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

import 'package:revenue_sdk/src/common/infrastructure/models/response/payout_request_record.dart';
import 'package:revenue_sdk/src/driver/presentation/wallet/wallet_grammar.dart';

/// Chip 987 — the payout status trail (frame 49k).
///
/// It FORKS on purpose. `Requested` is the only live node; `Paid` and
/// `Rejected` hang off it as ALTERNATIVES, because that is what the
/// doctype's Select actually models (Requested / Paid / Rejected /
/// Cancelled, terminal set at `wallet_payout_request.py:52`). Drawing them
/// in a line would promise that every request eventually pays, which is not
/// a promise this backend makes.
///
/// The line under the amount — *already taken off your balance* — repeats
/// the withdraw sheet's disclosure on purpose: `request_payout` debits at
/// request time (`payout.py:345`) BEFORE the row is inserted (`:349-368`),
/// and this is the screen the driver comes back to hours later, when he has
/// forgotten.
class PayoutStatusTrail extends StatelessWidget {
  const PayoutStatusTrail({super.key, required this.request, this.now});

  /// The still-live request this trail is about.
  final PayoutRequestRecord request;

  /// Injected in tests so "Today" is deterministic.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final live = statusView(PayoutStatus.requested);
    return Container(
      key: const Key('payoutStatusTrail'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: live.background,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: live.color),
      ),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppHelpers.getTranslation('payout_requested').toUpperCase(),
            style: AppStyle.interSemi(
              size: 10.5,
              letterSpacing: 1.2,
              color: live.color,
            ),
          ),
          14.verticalSpace,
          Text(
            AppHelpers.numberFormat(number: request.amount),
            key: const Key('payoutStatusTrailAmount'),
            style: AppStyle.interSemi(size: 22, color: live.color),
          ),
          8.verticalSpace,
          Text(
            _requestedLine(),
            key: const Key('payoutStatusTrailDebitNotice'),
            style: AppStyle.interRegular(
              size: 11,
              color: AppStyle.textDarkSecondary,
            ),
          ),
          16.verticalSpace,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _liveNode(live.color),
              12.horizontalSpace,
              Container(width: 1, height: 52.h, color: live.color),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _outcome('paid_into_your_account'),
                    10.verticalSpace,
                    _outcome('rejected_credited_back'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// "Today 17:20 · already taken off your balance".
  String _requestedLine() {
    final at = request.requestedAt;
    final notice =
        AppHelpers.getTranslation('already_taken_off_your_balance');
    if (at == null) return notice;
    final clock = DateFormat('HH:mm').format(at);
    final String day;
    switch (classifyDay(at, now ?? DateTime.now())) {
      case MovementDay.today:
        day = AppHelpers.getTranslation('today');
        break;
      case MovementDay.yesterday:
        day = AppHelpers.getTranslation('yesterday');
        break;
      case MovementDay.earlier:
        day = DateFormat('d MMM').format(at);
        break;
    }
    return '$day $clock · $notice';
  }

  Widget _liveNode(Color color) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
            ),
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
            ),
          ),
          6.verticalSpace,
          Text(
            AppHelpers.getTranslation('requested'),
            style: AppStyle.interNoSemi(size: 10, color: color),
          ),
        ],
      );

  /// One of the two alternatives. Hollow: neither has happened.
  Widget _outcome(String key) => Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppStyle.textDarkFaint, width: 2),
            ),
          ),
          10.horizontalSpace,
          Expanded(
            child: Text(
              AppHelpers.getTranslation(key),
              style: AppStyle.interRegular(
                size: 10,
                color: AppStyle.textDarkFaint,
              ),
            ),
          ),
        ],
      );
}
