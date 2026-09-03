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

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

import 'package:revenue_sdk/src/common/presentation/wallet/wallet_grammar.dart';

/// Chip 971 — the balance head of the driver wallet plane (frame 49f).
///
/// WHY THIS IS NOT base_sdk's [BaseWalletCard]. The shared card is reused
/// wherever its design fits, and here it does not: it renders the balance as
/// a SIGNED number inline after the word "Wallet"
/// (`base/lib/src/presentation/pages/profile/widgets/base_wallet_card.dart:
/// 147-158`) and hides the amount entirely at zero (`:101`). Frame 49f and
/// section 49's ruling 11 require the opposite on both counts — the balance
/// is a SENTENCE ("You owe R 1,240.00", never "−1,240"), and zero is a state
/// the driver must still be able to read. Bending [BaseWalletCard] into that
/// shape would change shared behaviour that the manager app renders today,
/// so this plane draws its own head and the shared card is left alone.
///
/// A NEGATIVE balance is deliberate and normal here: the driver keeps the
/// physical cash he collects and his ledger carries the debt. It is
/// coloured, not alarmed — stated as a fact with the reason under it.
class DriverBalanceHead extends StatelessWidget {
  const DriverBalanceHead({
    super.key,
    required this.balance,
    this.feesThisMonth,
    this.failed = false,
  });

  /// What the plane is showing. May be negative.
  final num balance;

  /// Gross delivery fees earned this calendar month; the row is omitted
  /// when it has not been read.
  final num? feesThisMonth;

  /// The authoritative read did not land, so this figure is the cached one.
  /// Said in one friendly line — never which backend cause it was.
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final tone = toneFor(balance);
    final Color accent = tone == BalanceTone.owing
        ? AppStyle.red
        : (tone == BalanceTone.available
            ? AppStyle.green
            : AppStyle.textDarkSecondary);
    return Container(
      key: const Key('driverBalanceHead'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(14.r),
        // The accent rail of frame 49f, drawn as a leading border so it
        // follows the card's radius instead of floating over it.
        border: BorderDirectional(start: BorderSide(color: accent, width: 4)),
      ),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppHelpers.getTranslation('balance').toUpperCase(),
            style: AppStyle.interSemi(
              size: 10.5,
              letterSpacing: 1.2,
              color: AppStyle.textDarkSecondary,
            ),
          ),
          14.verticalSpace,
          // THE SENTENCE. The figure is always the ABSOLUTE value: the
          // words carry the direction, so a driver never has to read a
          // minus sign to understand that he owes money.
          Text(
            '${AppHelpers.getTranslation(balanceLeadKey(tone))} '
            '${AppHelpers.numberFormat(number: balance.abs())}',
            key: const Key('driverBalanceSentence'),
            style: AppStyle.interSemi(size: 22, color: accent),
          ),
          if (tone == BalanceTone.owing) ...[
            10.verticalSpace,
            Text(
              AppHelpers.getTranslation(
                'cash_is_docked_the_moment_you_mark_delivered',
              ),
              key: const Key('driverBalanceWhyNegative'),
              style: AppStyle.interRegular(
                size: 11,
                color: AppStyle.textDarkSecondary,
              ),
            ),
          ],
          if (failed) ...[
            10.verticalSpace,
            Text(
              AppHelpers.getTranslation('we_could_not_refresh_your_balance'),
              key: const Key('driverBalanceStale'),
              style: AppStyle.interRegular(
                size: 11,
                color: AppStyle.textDarkFaint,
              ),
            ),
          ],
          if (feesThisMonth != null) ...[
            14.verticalSpace,
            Divider(height: 1, color: AppStyle.strokeDarkSubtle),
            14.verticalSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    AppHelpers.getTranslation('fees_earned_this_month'),
                    style: AppStyle.interRegular(
                      size: 11,
                      color: AppStyle.textDarkFaint,
                    ),
                  ),
                ),
                Text(
                  AppHelpers.numberFormat(number: feesThisMonth),
                  key: const Key('driverBalanceFeesThisMonth'),
                  style: AppStyle.interSemi(
                    size: 11,
                    color: AppStyle.textDarkSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
