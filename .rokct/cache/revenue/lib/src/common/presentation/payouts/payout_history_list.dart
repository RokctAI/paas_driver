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
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

import 'package:revenue_sdk/src/common/infrastructure/models/response/payout_request_record.dart';
import 'package:revenue_sdk/src/common/presentation/wallet/wallet_grammar.dart';

/// Chip 988 — the payout history (frame 49k).
///
/// Each row carries the amount, when it was asked for, the bank details as
/// they were SNAPSHOTTED onto the request (`payout.py:349-368` — not a
/// pointer at a saved account, so the row still reads correctly after the
/// account is removed), and the state.
///
/// A rejected or cancelled row carries the fact that matters more than the
/// reason: **the money went back**. `_release_hold`
/// (`wallet_payout_request.py:118-150`) credits it, latched by
/// `hold_released` so it happens at most once.
///
/// WHAT IS NOT DRAWN, because it does not exist: the rejection REASON.
/// Frame 49k puts it in words inside the row, and `Wallet Payout Request`
/// has no field for one — its fields are user, amount, bank_account, the
/// five snapshot columns, status, requested_at, resolved_at, resolver,
/// hold_taken, hold_released. Inventing a sentence the desk never wrote
/// would be worse than the silence, so the row states only what the ledger
/// can prove. Flagged, not forgotten.
class PayoutHistoryList extends StatelessWidget {
  const PayoutHistoryList({
    super.key,
    required this.requests,
    this.isLoading = false,
    this.failed = false,
    this.loadedOnce = false,
    this.now,
  });

  final List<PayoutRequestRecord> requests;
  final bool isLoading;

  /// The read did not land. ONE friendly line, never the cause.
  final bool failed;

  /// A read has completed — so an empty list is a real "he has never
  /// withdrawn", not "we have not looked yet".
  final bool loadedOnce;

  /// Injected in tests so "Today" is deterministic.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('payoutHistoryList'),
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(14.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Column(
        children: [
          if (failed)
            _note(
              AppHelpers.getTranslation('we_could_not_load_your_payouts'),
              const Key('payoutHistoryFailed'),
            )
          else if (isLoading && requests.isEmpty)
            _note(
              AppHelpers.getTranslation('loading'),
              const Key('payoutHistoryLoading'),
            )
          else if (requests.isEmpty)
            _note(
              AppHelpers.getTranslation(
                loadedOnce ? 'you_have_not_withdrawn_yet' : 'loading',
              ),
              const Key('payoutHistoryEmpty'),
            )
          else
            for (var i = 0; i < requests.length; i++) ...[
              _row(requests[i]),
              if (i != requests.length - 1)
                Divider(height: 1, color: AppStyle.strokeDarkSubtle),
            ],
        ],
      ),
    );
  }

  Widget _note(String text, Key key) => Padding(
        padding: EdgeInsets.symmetric(vertical: 18.h),
        child: Text(
          text,
          key: key,
          style: AppStyle.interRegular(
            size: 12,
            color: AppStyle.textDarkFaint,
          ),
        ),
      );

  Widget _row(PayoutRequestRecord request) {
    final view = statusView(request.status);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppHelpers.numberFormat(number: request.amount),
                      style: AppStyle.interNoSemi(size: 13),
                    ),
                    4.verticalSpace,
                    Text(
                      _subtitle(request),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyle.interRegular(
                        size: 10,
                        color: AppStyle.textDarkFaint,
                      ),
                    ),
                  ],
                ),
              ),
              12.horizontalSpace,
              if (view.labelKey.isNotEmpty) _chip(view),
            ],
          ),
          if (request.isCreditedBack) ...[
            10.verticalSpace,
            Container(
              key: const Key('payoutCreditedBackNote'),
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: view.background,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                '${AppHelpers.numberFormat(number: request.amount)} '
                '${AppHelpers.getTranslation(
                  'was_put_straight_back_into_your_balance',
                )}',
                style: AppStyle.interRegular(size: 9.5, color: view.color),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(PayoutStatusView view) => Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: view.background,
          borderRadius: BorderRadius.circular(11.r),
        ),
        child: Text(
          AppHelpers.getTranslation(view.labelKey),
          style: AppStyle.interNoSemi(size: 9.5, color: view.color),
        ),
      );

  /// "24 Aug 16:05 · Capitec •••• 8823" — the date, then the details as the
  /// request itself stored them.
  String _subtitle(PayoutRequestRecord request) {
    final parts = <String>[];
    final at = request.requestedAt;
    if (at != null) {
      final clock = DateFormat('HH:mm').format(at);
      switch (classifyDay(at, now ?? DateTime.now())) {
        case MovementDay.today:
          parts.add('${AppHelpers.getTranslation('today')} $clock');
          break;
        case MovementDay.yesterday:
          parts.add('${AppHelpers.getTranslation('yesterday')} $clock');
          break;
        case MovementDay.earlier:
          parts.add('${DateFormat('d MMM').format(at)} $clock');
          break;
      }
    }
    final bank = request.bankName?.trim();
    final masked = maskAccountNumber(request.accountNumber);
    final account = [
      if (bank != null && bank.isNotEmpty) bank,
      if (masked.isNotEmpty) masked,
    ].join(' ');
    if (account.isNotEmpty) parts.add(account);
    return parts.join(' · ');
  }
}
