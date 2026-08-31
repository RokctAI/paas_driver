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

import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

import 'package:revenue_sdk/src/common/infrastructure/models/response/bank_account_record.dart';
import 'package:revenue_sdk/src/driver/presentation/bank/bank_grammar.dart';

/// Frame 49r — sent: the money is already gone from the balance, and a person
/// still has to say yes.
///
/// THE ARITHMETIC IS THE POINT (chip 1015). `request_payout` writes the
/// wallet down at `pay/wallet/frappe/src/tenant/api/payout.py:345` BEFORE
/// the request row exists at `:349-368`, so the drop is instant,
/// unconditional and invisible to any pending flag — there is no reservation
/// and no shadow balance. A driver who sees a balance he does not recognise
/// is the whole risk of this endpoint, so the subtraction is drawn as
/// arithmetic rather than asserted as a claim: what he had, what has left,
/// what is there now.
///
/// Every figure comes from the call itself — `amount` and `new_balance` are
/// in the answer (`:379-384`) and the before figure is what the screen
/// already held. Nothing here is computed from a guess.
///
/// AMBER, NOT GREEN (chip 1014). This is not done, and a green confirmation
/// would say it was. Resolution is desk-side only: no client endpoint pays or
/// rejects, the admin moves the row, and the controller enforces one-way
/// transitions out of `Requested` into `TERMINAL_STATUSES`
/// (`wallet_payout_request.py:52, 66-107`). The credit-back on rejection or
/// cancellation runs through `_release_hold` (`:118-150`) behind the
/// `hold_released` latch, so it happens at most once — the money can neither
/// vanish nor return twice.
///
/// NO REFERENCE IS SHOWN. `Wallet Payout Request` declares no `autoname`, so
/// a request is named by a Frappe hash today — unquotable over a phone. The
/// frame drew a readable series and stamped it as a proposal; showing the
/// hash instead would be worse than showing nothing, so nothing is shown and
/// the flag is carried here in words.
///
/// NO CANCEL AFFORDANCE. `cancel_payout_request` exists and works
/// (`payout.py:388-427`), but who may cancel and until when is unsettled
/// policy that frame 49k flagged, and this sheet does not pre-empt it.
///
/// Sheet: takes no plane, so no back pill and no nav.
class PayoutSentSheet extends StatelessWidget {
  const PayoutSentSheet({
    super.key,
    required this.balanceBefore,
    required this.amount,
    required this.newBalance,
    required this.onDone,
    this.account,
  });

  /// What the screen held before the tap.
  final num balanceBefore;

  /// `amount`, as the server reported holding it.
  final num amount;

  /// `new_balance`, as the server reported it AFTER the debit.
  final num newBalance;

  /// The account the request names. Its details were COPIED onto the request
  /// row (`payout.py:349-368`), so later edits and removals cannot reach
  /// backwards into it — which is the sentence this block carries.
  final BankAccountRecord? account;

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
      ),
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 8.h,
        bottom: MediaQuery.paddingOf(context).bottom + 16.h,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 100.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppStyle.strokeDark,
                  borderRadius: BorderRadius.circular(40.r),
                ),
              ),
            ),
            16.verticalSpace,
            Text(
              AppHelpers.getTranslation('payout_requested'),
              key: const Key('payoutSentTitle'),
              style: AppStyle.interSemi(size: 16),
            ),
            8.verticalSpace,
            Text(
              AppHelpers.numberFormat(number: amount),
              style: AppStyle.interSemi(size: 28, color: AppStyle.primary),
            ),
            20.verticalSpace,
            _reconciliation(),
            if (account != null) ...[
              16.verticalSpace,
              _bankBlock(account!),
            ],
            16.verticalSpace,
            _pendingCard(),
            18.verticalSpace,
            CustomButton(
              key: const Key('payoutSentDone'),
              title: AppHelpers.getTranslation(TrKeys.done),
              background: AppStyle.primary,
              textColor: AppStyle.blackColor,
              onPressed: onDone,
            ),
          ],
        ),
      ),
    );
  }

  /// Chip 1015 — three lines, in the order the driver experiences them.
  Widget _reconciliation() => Container(
        key: const Key('payoutSentReconciliation'),
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: AppStyle.cardDarkAlt,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          children: [
            _row('balance_before', AppHelpers.numberFormat(number: balanceBefore)),
            8.verticalSpace,
            _row(
              'out_on_this_request',
              '− ${AppHelpers.numberFormat(number: amount)}',
              emphasis: true,
            ),
            10.verticalSpace,
            Divider(height: 1, color: AppStyle.strokeDarkSubtle),
            10.verticalSpace,
            _row('balance_now', AppHelpers.numberFormat(number: newBalance)),
          ],
        ),
      );

  Widget _row(String labelKey, String value, {bool emphasis = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppHelpers.getTranslation(labelKey),
            style: AppStyle.interRegular(
              size: 12,
              color: AppStyle.textDarkSecondary,
            ),
          ),
          Text(
            value,
            style: AppStyle.interNoSemi(
              size: 13,
              color: emphasis ? AppStyle.primary : AppStyle.textPrimary,
            ),
          ),
        ],
      );

  /// Chip 985's block, reused and now carrying the sentence that only makes
  /// sense at this moment: these details were copied onto the request.
  Widget _bankBlock(BankAccountRecord account) => Container(
        key: const Key('payoutSentBankBlock'),
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: AppStyle.cardDarkAlt,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppHelpers.getTranslation('paid_to').toUpperCase(),
              style: AppStyle.interSemi(
                size: 10,
                letterSpacing: 1.2,
                color: AppStyle.textDarkSecondary,
              ),
            ),
            8.verticalSpace,
            Text(
              [
                accountSummary(account),
                maskAccountNumber(account.accountNumber),
                if ((account.branchCode ?? '').trim().isNotEmpty)
                  '${AppHelpers.getTranslation('branch')} ${account.branchCode}',
              ].join(' · '),
              style: AppStyle.interNoSemi(size: 12),
            ),
            6.verticalSpace,
            Text(
              AppHelpers.getTranslation(
                'copied_onto_this_request_editing_the_account_later_'
                'wont_change_it',
              ),
              style: AppStyle.interRegular(
                size: 10.5,
                color: AppStyle.textDarkFaint,
              ),
            ),
          ],
        ),
      );

  /// Chip 1014 — the pending-approval statement, carrying the return path in
  /// the same breath.
  Widget _pendingCard() => Container(
        key: const Key('payoutSentPendingCard'),
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: AppStyle.cardDarkAlt,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppStyle.primary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppHelpers.getTranslation('someone_still_has_to_approve_it'),
              style: AppStyle.interNoSemi(size: 12, color: AppStyle.primary),
            ),
            6.verticalSpace,
            Text(
              '${AppHelpers.getTranslation('youll_see_it_here_as_paid_or_rejected_its_already_off_your_balance_and_if_its_rejected_or_cancelled')} '
              '${AppHelpers.numberFormat(number: amount)} '
              '${AppHelpers.getTranslation('comes_straight_back')}',
              style: AppStyle.interRegular(
                size: 11,
                color: AppStyle.textDarkSecondary,
              ),
            ),
          ],
        ),
      );
}
