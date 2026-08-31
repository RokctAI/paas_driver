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

/// Frame 49n — Withdraw, with nowhere to send it.
///
/// THE DEAD END, DRAWN HONESTLY. `request_payout` will not take a request
/// without a `Payout Bank Account` row: with no account named it calls
/// `_default_account` (`pay/wallet/frappe/src/tenant/api/payout.py:137-157`),
/// gets nothing back, and refuses at `:324-328`. Until this surface existed,
/// the Withdraw button would have failed on its first tap for every driver
/// who had ever used the app.
///
/// ORDER OF OPERATIONS MATTERS AND IS THE POINT. The app asks
/// `list_bank_accounts` when the sheet opens, so NO REQUEST IS EVER SENT and
/// nothing is held. The alternative — firing `request_payout` blind and
/// translating its refusal — would put a server sentence in front of a
/// driver, which is exactly what the house rule forbids.
///
/// THIS IS NOT AN ERROR CARD, and it is deliberately not drawn as one.
/// Nothing has failed. He simply has not done a thing nobody ever asked him
/// to do, because no screen in the app has ever asked. It is stated as an
/// absence with an action, not as a rejection — which is why the primary
/// action is `Add a bank account`, not Retry and not Close.
///
/// Sheet: takes no plane, so it carries no back pill and no nav.
class NoBankAccountSheet extends StatelessWidget {
  const NoBankAccountSheet({
    super.key,
    required this.available,
    required this.onAddBankAccount,
    required this.onDismiss,
  });

  /// The balance the page already holds — shown again, unchanged, because
  /// the whole message of chip 1002 is that it did not move.
  final num available;

  final VoidCallback onAddBankAccount;
  final VoidCallback onDismiss;

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
              AppHelpers.getTranslation(TrKeys.withdraw),
              style: AppStyle.interSemi(size: 16),
            ),
            18.verticalSpace,
            // Chip 1000 — the no-account state. The sheet opens onto the
            // reason instead of onto a field the driver cannot use.
            Text(
              AppHelpers.getTranslation(
                'you_havent_told_us_where_to_pay_you',
              ),
              key: const Key('noBankAccountReason'),
              style: AppStyle.interNoSemi(size: 14),
            ),
            8.verticalSpace,
            Text(
              AppHelpers.getTranslation(
                'add_the_bank_account_your_earnings_should_go_to_and_you_'
                'can_withdraw_from_this_screen_straight_away',
              ),
              style: AppStyle.interRegular(
                size: 12,
                color: AppStyle.textDarkSecondary,
              ),
            ),
            20.verticalSpace,
            // Chip 1001 — the way forward. The primary action of this state
            // is not Retry and not Close.
            CustomButton(
              key: const Key('noBankAccountAdd'),
              title: AppHelpers.getTranslation('add_a_bank_account'),
              background: AppStyle.primary,
              textColor: AppStyle.blackColor,
              onPressed: onAddBankAccount,
            ),
            18.verticalSpace,
            // Chip 1002 — the untouched-balance line, and the reason this
            // sheet exists rather than a translated server error. Saying so
            // is what stops a driver refreshing his balance for the next hour
            // looking for money that never moved.
            Container(
              key: const Key('noBankAccountUntouchedBalance'),
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppStyle.cardDarkAlt,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppHelpers.getTranslation('nothing_has_moved'),
                    style: AppStyle.interNoSemi(size: 12),
                  ),
                  6.verticalSpace,
                  Text(
                    '${AppHelpers.getTranslation('your_balance_is_still')} '
                    '${AppHelpers.numberFormat(number: available)}. '
                    '${AppHelpers.getTranslation('we_check_before_we_ask_so_no_request_was_sent_and_nothing_was_held')}',
                    style: AppStyle.interRegular(
                      size: 11,
                      color: AppStyle.textDarkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            14.verticalSpace,
            GestureDetector(
              key: const Key('noBankAccountDismiss'),
              onTap: onDismiss,
              child: Text(
                AppHelpers.getTranslation('not_now'),
                textAlign: TextAlign.center,
                style: AppStyle.interNoSemi(
                  size: 13,
                  color: AppStyle.textDarkSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
