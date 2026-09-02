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

// CHIP 932 of design strip section 49 — the cash-on-hand card.
//
// THE ONE NUMBER A DRIVER COULD NOT SEE AND MOST NEEDS TO. When a cash
// order settles, `settle_order` credits the driver his fee AND debits
// his wallet by the gross cash he is carrying (commerce settlement.py).
// So the wallet figure the shipped Balance tile showed was already net
// of money physically in his pocket, with nothing on screen explaining
// the gap. This card is that explanation.
//
// THE WORDING IS THE APPROVED WORDING, AND IT WAS ARGUED FOR. Frame 49d
// was REJECTED in its first draft for titling this card "Still to bank"
// with a sub-line reading "deposit before your next shift" — an
// obligation that DOES NOT EXIST IN THE CODE. There is no deposit
// doctype, no deposit due date, no banking step and nothing that reads
// one. The redraw keeps the ledger fact, which was always right, and
// drops the invention: "Cash on hand" / "docked from your wallet", full
// stop. Do not re-add a deadline, a deposit or a settlement obligation
// to this card without one existing first.
//
// It survives into the OFF-DUTY frame unchanged, for the reason it
// always did: going off duty does not hand the shop's money back.

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// CHIP 932 — cash the driver is physically carrying.
///
/// Held at FULL WEIGHT at every width. That is frame 49e's deliberate
/// priority call: the number a driver is personally liable for does not
/// get to be the thing that degrades when the phone is narrower. Only
/// the sub-line loses two words.
class CashOnHandCard extends StatelessWidget {
  const CashOnHandCard({
    super.key,
    required this.amount,
    required this.orderCount,
    this.compact = false,
  });

  /// `cash_on_hand` — the COD recorded at the door across the day, which
  /// settlement has ALREADY docked from his wallet.
  final num amount;

  /// `cash_order_count` — how many orders that came from.
  final int orderCount;

  /// Frame 49e's fold: the sub-line drops the word "already".
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppStyle.cardDarkAlt,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppStyle.strokeDarkSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppHelpers.getTranslation(TrKeys.cashOnHand),
                  style: AppStyle.interSemi(
                    size: 15,
                    color: AppStyle.textPrimary,
                  ),
                ),
                4.verticalSpace,
                Text(
                  _subLine(),
                  style: AppStyle.interNormal(
                    size: 12,
                    color: AppStyle.textDarkSecondary,
                  ),
                ),
              ],
            ),
          ),
          12.horizontalSpace,
          Text(
            AppHelpers.numberFormat(number: amount),
            style: AppStyle.interSemi(size: 20, color: AppStyle.textPrimary),
          ),
        ],
      ),
    );
  }

  /// "1 cash order · already docked from your wallet", or without
  /// "already" at the fold. The count is pluralised in the SDK's own
  /// keys rather than by string surgery on a translated word.
  String _subLine() {
    final orders = AppHelpers.getTranslation(
      orderCount == 1 ? TrKeys.cashOrderSingular : TrKeys.cashOrderPlural,
    );
    final docked = AppHelpers.getTranslation(
      compact
          ? TrKeys.dockedFromYourWallet
          : TrKeys.alreadyDockedFromYourWallet,
    );
    return '$orderCount $orders · $docked';
  }
}
